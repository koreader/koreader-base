/*
    KOReader: Bookeen input abstraction for Lua

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef _KO_INPUT_BOOKEEN_H
#define _KO_INPUT_BOOKEEN_H

#include <errno.h>
#include <fcntl.h>

#include "libue.h"

// Bookeen's AXP20 power driver emits power_supply uevents for charger changes, but the
// uevent payload is not exposed by libue. Read the online state from sysfs instead.
// Battery polling uses the same CHANGE event, so report only actual charge-state edges.
// The A13 USB stack exposes no host/data connection event; charging state is the only
// reliable signal available to the Bookeen frontend.
#define POWER_SUPPLY_SUBSYSTEM "power_supply"
// The AC supply may be absent on some Bookeen firmware variants.
#define USB_ONLINE_SYSFS "/sys/class/power_supply/usb/online"
#define AC_ONLINE_SYSFS  "/sys/class/power_supply/ac/online"

static void sendEvent(int fd, struct input_event* ev)
{
    if (write(fd, ev, sizeof(struct input_event)) == -1) {
        fprintf(stderr, "[ko-input]: Failed to generate fake event: %s\n", strerror(errno));
    }
}

// Return 1 for online, 0 for offline, or -1 when the node cannot be read.
static int readOnlineKnob(const char* path)
{
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd == -1) {
        fprintf(stderr, "[ko-input]: Failed to open %s: %s\n", path, strerror(errno));
        return -1;
    }

    char    buf[8] = { 0 };
    ssize_t len    = read(fd, buf, sizeof(buf) - 1U);
    close(fd);
    if (len <= 0) {
        fprintf(stderr, "[ko-input]: Failed to read %s: %s\n", path, strerror(errno));
        return -1;
    }

    // Bookeen sysfs renders the value as a decimal digit followed by a newline.
    return buf[0] == '0' ? 0 : 1;
}

// Return the combined USB/AC charging state.
static int isPluggedIn(void)
{
    int usb = readOnlineKnob(USB_ONLINE_SYSFS);
    int ac  = readOnlineKnob(AC_ONLINE_SYSFS);

    if (usb == -1 && ac == -1) {
        return -1;
    }

    return (usb == 1 || ac == 1) ? 1 : 0;
}

static void generateFakeEvent(int pipefd[2])
{
    close(pipefd[0]);

    struct uevent_listener listener = { 0 };
    int                    re       = ue_init_listener(&listener);
    if (re < 0) {
        fprintf(stderr, "[ko-input]: Failed to initialize libue listener: %s (error code %d)\n", strerror(-re), re);
        return;
    }

    // Seed edge detection with the state at startup.
    int last_state = isPluggedIn();
    if (last_state == -1) {
        fprintf(stderr, "[ko-input]: No readable power_supply online knob, charge events disabled.\n");
        ue_destroy_listener(&listener);
        return;
    }

    // EV_KEY events do not require a timestamp on Bookeen.
    struct input_event ev = { 0 };
    ev.type               = EV_KEY;
    ev.value              = 1;

    struct uevent uev;
    while ((re = ue_wait_for_event(&listener, &uev)) == 0) {
        if (!uev.subsystem || !UE_STR_EQ(uev.subsystem, POWER_SUPPLY_SUBSYSTEM)) {
            continue;
        }
        // ADD can make a previously unavailable supply visible.
        if (uev.action != UEVENT_ACTION_CHANGE && uev.action != UEVENT_ACTION_ADD) {
            continue;
        }

        int state = isPluggedIn();
        if (state == -1 || state == last_state) {
            // Ignore battery polling and unreadable states.
            continue;
        }
        last_state = state;

        ev.code = state ? CODE_FAKE_CHARGING : CODE_FAKE_NOT_CHARGING;
        sendEvent(pipefd[1], &ev);
    }

    ue_destroy_listener(&listener);
}

#endif
