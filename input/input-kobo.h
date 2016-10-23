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

#define KOBO_USB_DEVPATH_PLUG "/devices/platform/usb_plug"
#define KOBO_USB_DEVPATH_HOST "/devices/platform/usb_host"
#include "libue.h"

static void generateFakeEvent(int pipefd[2]) {
    int re;
    struct uevent_listener listener;
    struct uevent uev;
    struct input_event ev;

    close(pipefd[0]);

    ev.type = EV_KEY;
    ev.value = 1;

    re = ue_init_listener(&listener);
    if (re < 0) {
        fprintf(stderr, "[kobo-fake-event] Failed to initilize libue listener, err: %d\n", re);
        return;
    }

    while ((re = ue_wait_for_event(&listener, &uev)) == 0) {
        if (uev.action == UEVENT_ACTION_ADD
                && uev.devpath
                && (UE_STR_EQ(uev.devpath, KOBO_USB_DEVPATH_PLUG)
                    || UE_STR_EQ(uev.devpath, KOBO_USB_DEVPATH_HOST))) {
            ev.code = CODE_FAKE_CHARGING;
        } else if (uev.action == UEVENT_ACTION_REMOVE
                && uev.devpath
                && (UE_STR_EQ(uev.devpath, KOBO_USB_DEVPATH_PLUG)
                    || UE_STR_EQ(uev.devpath, KOBO_USB_DEVPATH_HOST))) {
            ev.code = CODE_FAKE_NOT_CHARGING;
        } else {
            continue;
        }
        if (write(pipefd[1], &ev, sizeof(struct input_event)) == -1) {
            fprintf(stderr, "[ko-fake-event] Failed to generate fake event.\n");
            return;
        }
    }
}

#endif
