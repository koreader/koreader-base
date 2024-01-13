/*
    KOReader: kobo input abstraction for Lua
    Copyright (C) 2016 Qinping Hou <dave2008713@gmail.com>

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

#ifndef _KO_INPUT_KOBO_H
#define _KO_INPUT_KOBO_H

#define USBPLUG_DEVPATH "/devices/platform/usb_plug"
#define USBHOST_DEVPATH "/devices/platform/usb_host"
#define PLATFORMSOC_DEVPATH "/devices/platform/soc"

#include "libue.h"

static void sendEvent(int fd, struct input_event* ev)
{
    if (write(fd, ev, sizeof(struct input_event)) == -1) {
        fprintf(stderr, "[ko-input]: Failed to generate fake event.\n");
    }
}

// Using strtol right is *fun*...
static int strtol_d(const char* str)
{
    char* endptr;
    errno = 0;
    long int val = strtol(str, &endptr, 10);
    if (errno || endptr == str || *endptr || (int) val != val) {
        // strtol failure || no digits were found || trailing garbage || cast truncation
        return -1; // this will conveniently never match a real evdev number ;).
    }

    return (int) val;
}

static void generateFakeEvent(int pipefd[2])
{
    close(pipefd[0]);

    struct uevent_listener listener = { 0 };
    int                    re       = ue_init_listener(&listener);
    if (re < 0) {
        fprintf(stderr, "[ko-input]: Failed to initialize libue listener (%d)\n", re);
        return;
    }

    // NOTE: We leave the timestamp at zero, we don't know the system's evdev clock source right now,
    //       and zero works just fine for EV_KEY events.
    struct input_event ev = { 0 };
    ev.type               = EV_KEY;
    ev.value              = 1;

    struct uevent uev;
    while ((re = ue_wait_for_event(&listener, &uev)) == 0) {
        if (uev.devpath && UE_STR_EQ(uev.devpath, USBPLUG_DEVPATH)) {
            switch (uev.action) {
                case UEVENT_ACTION_ADD:
                    ev.code = CODE_FAKE_CHARGING;
                    sendEvent(pipefd[1], &ev);
                    break;
                case UEVENT_ACTION_REMOVE:
                    ev.code = CODE_FAKE_NOT_CHARGING;
                    sendEvent(pipefd[1], &ev);
                    break;
                default:
                    // NOP
                    break;
            }
        } else if (uev.devpath && UE_STR_EQ(uev.devpath, USBHOST_DEVPATH)) {
            switch (uev.action) {
                case UEVENT_ACTION_ADD:
                    ev.code = CODE_FAKE_USB_PLUGGED_IN_TO_HOST;
                    sendEvent(pipefd[1], &ev);
                    break;
                case UEVENT_ACTION_REMOVE:
                    ev.code = CODE_FAKE_USB_PLUGGED_OUT_OF_HOST;
                    sendEvent(pipefd[1], &ev);
                    break;
                default:
                    // NOP
                    break;
            }
        } else if (uev.subsystem && (UE_STR_EQ(uev.subsystem, "input")) &&
                   uev.devname && (UE_STR_EQ(uev.devname, "input/event")) &&
                   uev.devpath && (UE_STR_EQ(uev.devpath, PLATFORMSOC_DEVPATH))) {
            // Issue usb fake events when an external evdev input device is connected through OTG. Such a devpath mike look like:
            // /devices/platform/soc/2100000.aips-bus/2184000.usb/ci_hdrc.0/usb1/1-1/1-1:1.0/0003:1532:021A.001C/input/input31/event4 (on a Libra 2)
            // /devices/platform/soc/5101000.ohci0-controller/usb2/2-1/2-1:1.0/0003:1532:0118.0004/input/input7/event4 (on an Elipsa)
            // c.f., https://github.com/koreader/koreader-base/pull/1520
            switch (uev.action) {
                case UEVENT_ACTION_ADD:
                    ev.code = CODE_FAKE_USB_DEVICE_PLUGGED_IN;
                    // Pass along the evdev number
                    ev.value = strtol_d(uev.devname + sizeof("input/event") - 1U); // i.e., start right after the t of event
                    sendEvent(pipefd[1], &ev);
                    ev.value = 1;
                    break;
                case UEVENT_ACTION_REMOVE:
                    ev.code = CODE_FAKE_USB_DEVICE_PLUGGED_OUT;
                    ev.value = strtol_d(uev.devname + sizeof("input/event") - 1U);
                    sendEvent(pipefd[1], &ev);
                    ev.value = 1;
                    break;
                default:
                    // NOP
                    break;
            }
        }
    }
}

#endif
