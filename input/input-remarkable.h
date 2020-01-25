/*
    KOReader: Remarkable input abstraction for Lua

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

#ifndef _KO_INPUT_REMARKABLE_H
#define _KO_INPUT_REMARKABLE_H

#define CHARGER_DEVPATH "/devices/soc0/soc/2100000.aips-bus/2184000.usb/power_supply/imx_usb_charger"
#define CHARGER_ONLINE_PATH "/sys" CHARGER_DEVPATH "/online"
#define BATTERY_DEVPATH "/devices/soc0/soc/2100000.aips-bus/21a0000.i2c/i2c-0/0-0055/power_supply/bq27441-0"
#define BATTERY_STATUS_PATH "/sys" BATTERY_DEVPATH "/status"

#include "libue.h"
#include "input.h"

static size_t read_file(char const* path, char* buf, size_t buflen)
{
    FILE* file = fopen(path, "r");
    if (!file) {
        fprintf(stderr, "Could not open '%s'\n", path);
        return 0;
    }
    size_t n = fread(buf, 1, buflen - 1, file);
    buf[n] = '\0';
    fclose(file);
    return n;
}

static void input_write_event(int fd, int code)
{
    struct input_event ev = { .type = EV_KEY, .code = code, .value = 1 };
    if (write(fd, &ev, sizeof(ev)) == -1) {
        fprintf(stderr, "Failed to generate fake event.\n");
    }
}

static void generateFakeEvent(int pipefd[2]) {
    int re;
    struct uevent_listener listener;
    struct uevent uev;

    close(pipefd[0]);

    re = ue_init_listener(&listener);
    if (re < 0) {
        fprintf(stderr, "[remarkable-fake-event] Failed to initilize libue listener, err: %d\n", re);
        return;
    }

    int charger_state = -1;
    int battery_state = -1;

    char fbuf[32];
    while ((re = ue_wait_for_event(&listener, &uev)) == 0) {
        if (uev.action == UEVENT_ACTION_CHANGE && uev.devpath) {
            if (UE_STR_EQ(uev.devpath, CHARGER_DEVPATH)) {
                if (read_file(CHARGER_ONLINE_PATH, fbuf, sizeof(fbuf))) {
                    int new_state = strcmp(fbuf, "1\n") == 0? 1 : 0;
                    if (new_state != charger_state) {
                        input_write_event(pipefd[1], new_state? CODE_FAKE_USB_PLUG_IN : CODE_FAKE_USB_PLUG_OUT);
                    }
                    charger_state = new_state;
                }
            }
            else if (UE_STR_EQ(uev.devpath, BATTERY_DEVPATH)) {
                if (read_file(BATTERY_STATUS_PATH, fbuf, sizeof(fbuf))) {
                    int new_state = strcmp(fbuf, "Charging\n") == 0? 1 : 0;
                    if (new_state != battery_state) {
                        input_write_event(pipefd[1], new_state? CODE_FAKE_CHARGING : CODE_FAKE_NOT_CHARGING);
                    }
                    battery_state = new_state;
                }
            }
        }
    }
}

#endif
