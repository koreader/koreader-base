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

#include "libue.h"

static void sendEvent(int fd, struct input_event* ev)
{
    if (write(fd, ev, sizeof(struct input_event)) == -1) {
        fprintf(stderr, "[ko-input]: Failed to generate fake event.\n");
    }
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
                    ev.code = CODE_FAKE_USB_PLUG_IN;
                    sendEvent(pipefd[1], &ev);
                    break;
                case UEVENT_ACTION_REMOVE:
                    ev.code = CODE_FAKE_USB_PLUG_OUT;
                    sendEvent(pipefd[1], &ev);
                    break;
                default:
                    // NOP
                    break;
            }
        }
    }
}

#endif
