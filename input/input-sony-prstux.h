/*
    KOReader: Sony PRSTUX input abstraction for Lua

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

#ifndef _KO_INPUT_SONY_PRSTUX_H
#define _KO_INPUT_SONY_PRSTUX_H

#define SONY_PRSTUX_BATT_DEVPATH "/devices/platform/imx-i2c.1/i2c-1/1-0049/twl6030_bci/power_supply/twl6030_battery"
#include "libue.h"

#define SONY_PRSTUX_BATTERY_STATE_CHARGING     0
#define SONY_PRSTUX_BATTERY_STATE_DISCHARGING  1
#define SONY_PRSTUX_BATTERY_STATE_NOT_CHARGING 2
#define SONY_PRSTUX_BATTERY_STATE_FULL         3
#define SONY_PRSTUX_BATTERY_STATE_UNKNOWN      4

static int getBatteryState(void) {
    int state = SONY_PRSTUX_BATTERY_STATE_DISCHARGING;
    FILE* file = NULL;
    size_t bytes_read;
    char buffer[256] = { 0 };

    file = fopen("/sys" SONY_PRSTUX_BATT_DEVPATH"/status", "r");
    bytes_read = fread(buffer, 1, 256, file);

    if (strcmp(buffer, "Charging\n") == 0) {
        state = SONY_PRSTUX_BATTERY_STATE_CHARGING;
    } else if (strcmp(buffer, "Full\n") == 0) {
        state = SONY_PRSTUX_BATTERY_STATE_FULL;
    } else if (strcmp(buffer, "Discharging\n") == 0) {
        state = SONY_PRSTUX_BATTERY_STATE_DISCHARGING;
    } else if (strcmp(buffer, "Not Charging\n") == 0) {
        state = SONY_PRSTUX_BATTERY_STATE_NOT_CHARGING;
    } else {
        state = SONY_PRSTUX_BATTERY_STATE_UNKNOWN;
    }
    //fprintf(stderr, "battery state string: %s\n", buffer);

    fclose(file);
    return state;
}

static void sendEvent(int fd, struct input_event* ev) {
    if (write(fd, ev, sizeof(struct input_event)) == -1) {
        fprintf(stderr, "Failed to generate fake event.\n");
    }
}

static void generateFakeEvent(int pipefd[2]) {
    int re;
    struct uevent_listener listener;
    struct uevent uev;
    struct input_event ev;
    int prev_battery_state, battery_state;

    close(pipefd[0]);

    battery_state = getBatteryState();
    prev_battery_state = battery_state;

    //fprintf(stderr, "[fake] initial battery state: %d\n", battery_state);

    ev.type = EV_KEY;
    ev.value = 1;

    re = ue_init_listener(&listener);
    if (re < 0) {
        fprintf(stderr, "[sony-prstux-fake-event] Failed to initialize libue listener (%d)\n", re);
        return;
    }

    while ((re = ue_wait_for_event(&listener, &uev)) == 0) {
        if (uev.action == UEVENT_ACTION_CHANGE
                && uev.devpath
                && (UE_STR_EQ(uev.devpath, SONY_PRSTUX_BATT_DEVPATH))) {

            battery_state = getBatteryState();
            //fprintf(stderr, "[fake] battery state now: %d\n", battery_state);
            if (prev_battery_state != battery_state) {
                switch(battery_state) {
                    case SONY_PRSTUX_BATTERY_STATE_CHARGING:
                        ev.code = CODE_FAKE_USB_PLUGGED_IN_TO_HOST;
                        sendEvent(pipefd[1], &ev);
                        ev.code = CODE_FAKE_CHARGING;
                        sendEvent(pipefd[1], &ev);
                    break;
                    case SONY_PRSTUX_BATTERY_STATE_FULL:
                        ev.code = CODE_FAKE_NOT_CHARGING;
                        sendEvent(pipefd[1], &ev);
                    break;
                    case SONY_PRSTUX_BATTERY_STATE_DISCHARGING:
                        ev.code = CODE_FAKE_USB_PLUGGED_OUT_OF_HOST;
                        sendEvent(pipefd[1], &ev);
                        ev.code = CODE_FAKE_NOT_CHARGING;
                        sendEvent(pipefd[1], &ev);
                    break;
                }
            }
            prev_battery_state = battery_state;
        }
    }
}

#endif
