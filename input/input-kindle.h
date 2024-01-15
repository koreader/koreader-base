/*
    KOReader: kindle input abstraction for Lua
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

#ifndef _KO_INPUT_KINDLE_H
#define _KO_INPUT_KINDLE_H

#include "popen_noshell.h"
static struct popen_noshell_pass_to_pclose pclose_arg;

static void slider_handler(int sig)
{
    /* Kill lipc-wait-event properly on exit */
    if(pclose_arg.pid != 0) {
        /* Be a little more gracious, lipc seems to handle SIGINT properly */
        kill(pclose_arg.pid, SIGINT);
    }
}

// Using strtol right is *fun*...
static int strtol_d(const char* str)
{
    char* endptr;
    errno = 0;
    long int val = strtol(str, &endptr, 10);
    // NOTE: The string we're fed will have trailing garbage (a space followed by an LF) (because lipc & fgets), so we mostly ignore endptr...
    if (errno || endptr == str || (int) val != val) {
        // strtol failure || no digits were found || cast truncation
        return -1; // this will conveniently never match a real powerd constant ;).
    }

    return (int) val;
}

static void sendEvent(int fd, struct input_event* ev)
{
    if (write(fd, ev, sizeof(struct input_event)) == -1) {
        fprintf(stderr, "[ko-input]: Failed to generate fake event.\n");
    }
}

static void generateFakeEvent(int pipefd[2]) {
    /* We send a SIGTERM to this child on exit, trap it to kill lipc properly. */
    signal(SIGTERM, slider_handler);

    close(pipefd[0]);

    // NOTE: We leave the timestamp at zero, we don't know the system's evdev clock source right now,
    //       and zero works just fine for EV_KEY events.
    struct input_event ev = { 0 };
    ev.type               = EV_KEY;
    ev.value              = 1;

    /* listen power slider events (listen for ever for multiple events) */
    char *argv[] = {
        "lipc-wait-event", "-m", "-s", "0", "com.lab126.powerd",
        "goingToScreenSaver,outOfScreenSaver,exitingScreenSaver,charging,notCharging,wakeupFromSuspend,readyToSuspend", (char *)NULL
    };
    /* @TODO  07.06 2012 (houqp)
     * plugin and out event can only be watched by:
     * lipc-wait-event com.lab126.hal usbPlugOut,usbPlugIn */
    FILE *fp = popen_noshell("lipc-wait-event", (const char * const *)argv, "r", &pclose_arg, 0);
    if (!fp) {
        err(EXIT_FAILURE, "popen_noshell()");
    }

    /* Flush to get rid of buffering issues? */
    fflush(fp);

    char std_out[256];
    while (fgets(std_out, sizeof(std_out), fp)) {
        if (std_out[0] == 'g') {
            ev.code = CODE_FAKE_IN_SAVER;
            // Pass along the source constant
            ev.value = strtol_d(std_out + sizeof("goingToScreenSaver"));
            sendEvent(pipefd[1], &ev);
            ev.value = 1;
        } else if(std_out[0] == 'o') {
            ev.code = CODE_FAKE_OUT_SAVER;
            // Pass along the source constant
            ev.value = strtol_d(std_out + sizeof("outOfScreenSaver"));
            sendEvent(pipefd[1], &ev);
            ev.value = 1;
        } else if(std_out[0] == 'e') {
            ev.code = CODE_FAKE_EXIT_SAVER;
            sendEvent(pipefd[1], &ev);
        } else if((std_out[0] == 'u') && (std_out[7] == 'I')) {
            ev.code = CODE_FAKE_USB_PLUGGED_IN_TO_HOST;
            sendEvent(pipefd[1], &ev);
        } else if((std_out[0] == 'u') && (std_out[7] == 'O')) {
            ev.code = CODE_FAKE_USB_PLUGGED_OUT_OF_HOST;
            sendEvent(pipefd[1], &ev);
        } else if(std_out[0] == 'c') {
            ev.code = CODE_FAKE_CHARGING;
            sendEvent(pipefd[1], &ev);
        } else if(std_out[0] == 'n') {
            ev.code = CODE_FAKE_NOT_CHARGING;
            sendEvent(pipefd[1], &ev);
        } else if(std_out[0] == 'w') {
            ev.code = CODE_FAKE_WAKEUP_FROM_SUSPEND;
            // Pass along the time spent in suspend
            ev.value = strtol_d(std_out + sizeof("wakeupFromSuspend"));
            sendEvent(pipefd[1], &ev);
            ev.value = 1;
        } else if(std_out[0] == 'r') {
            ev.code = CODE_FAKE_READY_TO_SUSPEND;
            // Pass along the delay
            ev.value = strtol_d(std_out + sizeof("readyToSuspend"));
            sendEvent(pipefd[1], &ev);
            ev.value = 1;
        } else {
            fprintf(stderr, "[ko-input]: Unrecognized powerd event: `%.*s`.\n", (int) (sizeof(std_out) - 1U), std_out);
        }
    }

    int status = pclose_noshell(&pclose_arg);
    if (status == -1) {
        err(EXIT_FAILURE, "pclose_noshell()");
    } else {
        if (WIFEXITED(status)) {
            printf("lipc-wait-event exited normally with status: %d\n", WEXITSTATUS(status));
        } else if (WIFSIGNALED(status)) {
            printf("lipc-wait-event was killed by signal %d\n", WTERMSIG(status));
        } else if (WIFSTOPPED(status)) {
            printf("lipc-wait-event was stopped by signal %d\n", WSTOPSIG(status));
        } else if (WIFCONTINUED(status)) {
            printf("lipc-wait-event continued\n");
        }
    }
}

#endif
