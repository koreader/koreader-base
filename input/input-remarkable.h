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

#define MACHINE_PATH "/sys/devices/soc0/machine"
#define CHARGER_DEVPATH "/devices/soc0/soc/2100000.aips-bus/2184000.usb/power_supply/imx_usb_charger"
#define CHARGER_ONLINE_PATH "/sys" CHARGER_DEVPATH "/online"
#define BATTERY_DEVPATH "/devices/soc0/soc/2100000.aips-bus/21a0000.i2c/i2c-0/0-0055/power_supply/bq27441-0"
#define BATTERY_STATUS_PATH "/sys" BATTERY_DEVPATH "/status"

#include "libue.h"
#include "input.h"
#include "popen_noshell.h"
static struct popen_noshell_pass_to_pclose pclose_arg;

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

/*
 * On wakeup, reMarkable 2 does not send Power Button events
 * So we watch DBus and insert a "Power Button Released" event when the rM2 wakes up
 */
static void generateFakeEventRM2(int pipefd) {
    FILE *fp;
    char std_out[256];
    int status;
    struct input_event ev;

    ev.type = EV_KEY;
    ev.code = 116; // rM2 "Power button" key
    ev.value = 0; // Key released

    char *argv[] = { "dbus-monitor", "--system", "member='PrepareForSleep'", (char *)NULL };
    fp = popen_noshell("dbus-monitor", (const char * const *)argv, "r", &pclose_arg, 0);
    if (!fp) {
        fprintf(stderr, "[remarkable-fake-event] Failed to popen_noshell dbus-monitor\n");
        return;
    }

    fflush(fp);

    while (fgets(std_out, sizeof(std_out), fp)) {
        if (!strncmp(std_out, "   boolean false", 16)) {
            gettimeofday(&ev.time, NULL);
            if (write(pipefd, &ev, sizeof(struct input_event)) == -1) {
                fprintf(stderr, "Failed to generate Power Button Released event.\n");
            }
        }
    }

    status = pclose_noshell(&pclose_arg);
    if (status == -1) {
        err(EXIT_FAILURE, "pclose_noshell()");
    } else {
        if (WIFEXITED(status)) {
            printf("dbus-monitor exited normally with status: %d\n", WEXITSTATUS(status));
        } else if (WIFSIGNALED(status)) {
            printf("dbus-monitor was killed by signal %d\n", WTERMSIG(status));
        } else if (WIFSTOPPED(status)) {
            printf("dbus-monitor was stopped by signal %d\n", WSTOPSIG(status));
        } else if (WIFCONTINUED(status)) {
            printf("dbus-monitor continued\n");
        }
    }
}

static void generateFakeEventRM1(int pipefd) {
    int re;
    struct uevent_listener listener;
    struct uevent uev;

    re = ue_init_listener(&listener);
    if (re < 0) {
        fprintf(stderr, "[remarkable-fake-event] Failed to initialize libue listener (%d)\n", re);
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
                        input_write_event(pipefd, new_state? CODE_FAKE_USB_PLUGGED_IN_TO_HOST : CODE_FAKE_USB_PLUGGED_OUT_OF_HOST);
                    }
                    charger_state = new_state;
                }
            }
            else if (UE_STR_EQ(uev.devpath, BATTERY_DEVPATH)) {
                if (read_file(BATTERY_STATUS_PATH, fbuf, sizeof(fbuf))) {
                    int new_state = strcmp(fbuf, "Charging\n") == 0? 1 : 0;
                    if (new_state != battery_state) {
                        input_write_event(pipefd, new_state? CODE_FAKE_CHARGING : CODE_FAKE_NOT_CHARGING);
                    }
                    battery_state = new_state;
                }
            }
        }
    }
}

static void generateFakeEvent(int pipefd[2]) {
    close(pipefd[0]);

    char mbuf[32];
    if (read_file(MACHINE_PATH, mbuf, sizeof(mbuf)) && !strncmp(mbuf, "reMarkable 2.0", 14)) {
        generateFakeEventRM2(pipefd[1]);
    } else {
        generateFakeEventRM1(pipefd[1]);
    }
}

#endif
