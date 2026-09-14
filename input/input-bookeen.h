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

// NOTE: This deliberately does *not* define USBPLUG_DEVPATH / USBHOST_DEVPATH the way the
//       kobo and cervantes headers do. Those name `/devices/platform/usb_plug` and
//       `/devices/platform/usb_host`, which are NTX board glue: no such platform devices
//       exist in this Allwinner A13 vendor kernel. The only USB platform devices here are
//       `sw_usb_udc` and `sw_hcd_host0`, and they are registered once at init from
//       drivers/usb/sun5i_usb/manager/usbc0_platform.c:129 -- not on plug/unplug. Copying
//       those defines over is exactly why this file stayed a stub; matching on them would
//       compile fine and never fire.
//
//       What we do get is the AXP20 PMIC. On a charger IRQ (AXP20_IRQ_ACIN / USBIN / ACRE /
//       USBRE / CHAOV / ...), axp_battery_event() calls axp_change()
//       (drivers/power/axp_power/axp20-sply-cou.c:601), which refreshes usb_valid/ac_valid
//       from the chip and then calls power_supply_changed(&charger->batt) -- that lands as a
//       KOBJ_CHANGE uevent on the `power_supply` class (drivers/power/power_supply_core.c:60).
//       The sysfs_notify() on usb/online immediately after it emits *no* uevent, so the
//       battery device's CHANGE event is the only edge visible from userspace.
//
//       Two consequences shape the code below:
//
//       1. The uevent carries POWER_SUPPLY_NAME= and every property
//          (drivers/power/power_supply_sysfs.c:242), but libue's `struct uevent` only ever
//          exposes ACTION/DEVPATH/SUBSYSTEM/MODALIAS/DEVNAME -- so that payload is
//          unreachable, and we have to read sysfs to learn what actually changed.
//       2. The same battery CHANGE event also fires on every battery-percentage change
//          (axp20-sply-cou.c:1827, on the charger's polling work), so it is *not* a charge
//          edge by itself. Hence the explicit edge detection below; without it KOReader
//          would broadcast a Charging event every time the gauge moved.
//
//       There is no data-aware-host signal anywhere in this SoC's USB stack -- the gadget
//       never surfaces enumeration to userspace -- so Charging/NotCharging is all we can
//       honestly report, and CODE_FAKE_USB_PLUGGED_{IN_TO,OUT_OF}_HOST is left unused. That
//       is fine here: canToggleMassStorage is `no` on bookeen, and the frontend deliberately
//       wires UsbPlugIn/UsbPlugOut to the same handlers as Charging/NotCharging
//       (c.f. Bookeen:setEventHandlers).
#define POWER_SUPPLY_SUBSYSTEM "power_supply"
// `usb` is registered unconditionally, `ac` only when AXP20_CHARGE_STATUS bit 1 is clear
// (axp20-sply-cou.c:2007-2014), so the latter may legitimately not exist. Tolerate that.
#define USB_ONLINE_SYSFS "/sys/class/power_supply/usb/online"
#define AC_ONLINE_SYSFS  "/sys/class/power_supply/ac/online"

static void sendEvent(int fd, struct input_event* ev)
{
    if (write(fd, ev, sizeof(struct input_event)) == -1) {
        fprintf(stderr, "[ko-input]: Failed to generate fake event.\n");
    }
}

// Returns 1 (online), 0 (offline), or -1 if the knob doesn't exist / can't be read.
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

    // sysfs renders these as "%d\n", so the first byte is the digit.
    return buf[0] == '0' ? 0 : 1;
}

// 1 if we're on external power, 0 if not, -1 if we cannot tell at all.
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

    // Seed the edge detector with the state we started in. If neither knob is readable there
    // is nothing this process can ever usefully report, so say so once and stop rather than
    // spin on uevents we cannot interpret.
    int last_state = isPluggedIn();
    if (last_state == -1) {
        fprintf(stderr, "[ko-input]: No readable power_supply online knob, charge events disabled.\n");
        ue_destroy_listener(&listener);
        return;
    }

    // NOTE: We leave the timestamp at zero, like the other platforms: we don't know the
    //       system's evdev clock source here, and zero is fine for EV_KEY.
    struct input_event ev = { 0 };
    ev.type               = EV_KEY;
    ev.value              = 1;

    struct uevent uev;
    while ((re = ue_wait_for_event(&listener, &uev)) == 0) {
        if (!uev.subsystem || !UE_STR_EQ(uev.subsystem, POWER_SUPPLY_SUBSYSTEM)) {
            continue;
        }
        // power_supply_changed() only ever emits CHANGE; ADD is the class device showing up,
        // which is worth a re-read too (it means a supply we couldn't see before now exists).
        if (uev.action != UEVENT_ACTION_CHANGE && uev.action != UEVENT_ACTION_ADD) {
            continue;
        }

        int state = isPluggedIn();
        if (state == -1 || state == last_state) {
            // Almost always the battery-percentage notification. Ignore it.
            continue;
        }
        last_state = state;

        ev.code = state ? CODE_FAKE_CHARGING : CODE_FAKE_NOT_CHARGING;
        sendEvent(pipefd[1], &ev);
    }

    ue_destroy_listener(&listener);
}

#endif
