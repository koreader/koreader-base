/*
    KOReader: pocketbook input abstraction for Lua
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

#ifndef _KO_INPUT_PB_H
#define _KO_INPUT_PB_H

#include "inkview.h"
#include <dlfcn.h>
#include <pthread.h>

#define ABS_MT_SLOT     0x2f

typedef struct real_iv_mtinfo_s {
    int active;
    int x;
    int y;
    int pressure;
    int rsv_1;
    int rsv_2;
    int rsv_3; // iv_mtinfo from SDK 481 misses this field
    int rsv_4; // iv_mtinfo from SDK 481 misses this field
} real_iv_mtinfo;

/* Since SDK 481 provides a wrong iv_mtinfo that has 8 bytes less in length
 * when indexing iv_mtinfo in the second slot the x and y will be wrong
 * we currently fix this by making a real iv_mtinfo struct, this is dirty hack
 * because of the lame API design of GetTouchInfo. It could be better to pass
 * the slot parameter to GetTouchInfo which returns only one iv_mtinfo for that slot. */
#define iv_mtinfo real_iv_mtinfo

static inline void genEmuEvent(int fd, int type, int code, int value) {
    struct input_event input;

    input.type = type;
    input.code = code;
    input.value = value;

    gettimeofday(&input.time, NULL);
    if (write(fd, &input, sizeof(struct input_event)) == -1) {
        fprintf(stderr, "Failed to generate emu event.\n");
    }

    return;
}

iv_mtinfo* (*gti)(void); /* Pointer to GetTouchInfo() function. */
static void get_gti_pointer() {
    /* This gets the pointer to the GetTouchInfo() function if it is available. */
    void *handle;

    if ((handle = dlopen("libinkview.so", RTLD_LAZY))) {
        *(void **) (&gti) = dlsym(handle, "GetTouchInfo");
        dlclose(handle);
    } else {
        gti = NULL;
    }
}

static inline void debug_mtinfo(iv_mtinfo *mti) {
    int i;
    for (i = 0; i < 32; i++) {
        if (i > 0) printf(":");
        printf("%02X", ((char*)mti)[i]);
    }
    printf("\n");
}

/*
 * The PocketBook has an auto-suspend-feature, which puts the reader to sleep
 * after approximately two seconds "inactivity in the current eventhandler".
 *
 * The handler (pb_event_handle) runs via InkViewMain in a forked-off process
 * and just relays incoming events like keypress / touch via a pipe to the
 * main-koreader-process when they occur. In consequence, the forked process
 * quickly becomes idle w/o external events, leading to suspension of the
 * whole device.
 *
 * This breaks the initial loading of modules and books.
 *
 * There are multiple functions which can affect auto-suspension: Beside
 * iv_sleepmode() which controls if auto-suspension is enabled at all, the
 * function SetHardTimer() makes it possible to execute a callback after a
 * given amount of time. SetHardTimer() will wake the Reader if it is
 * suspended and suspension will not occur while the callback is executed.
 *
 * However, both functions will not work properly if not called _from within
 * the current eventhandler_.
 *
 * SendEventTo() can be used to send an event to the current eventhandler of a
 * specific (system) task. GetCurrentTask() returns the caller's currently
 * active task.
 */

/*
 * define a fake-event which can be send via SendEventTo into
 * pb_event_handle()
 */
#define PB_SPECIAL_SUSPEND 333

/* callback to disable suspension */
void disable_suspend(void) {
    iv_sleepmode(0);
}

/* callback to enable suspension */
void enable_suspend(void) {
    iv_sleepmode(1);
}

static int external_suspend_control = 0;

void fallback_enable_suspend(void) {
    if (external_suspend_control == 0) {
        enable_suspend();
    }
}

static int send_to_event_handler(int type, int par1, int par2) {
    SendEventTo(GetCurrentTask(), type, par1, par2);
}


static int setSuspendState(lua_State *L) {
    send_to_event_handler(
        PB_SPECIAL_SUSPEND,
        luaL_checkint(L, 1),
        luaL_checkint(L, 2)
    );
}

int touch_pointers = 0;
static int pb_event_handler(int type, int par1, int par2) {
    // printf("ev:%d %d %d\n", type, par1, par2);
    // fflush(stdout);
    int i;
    iv_mtinfo *mti;

    // general settings in only possible in forked process
    if (type == EVT_INIT) {
        SetPanelType(PANEL_DISABLED);
        get_gti_pointer();
        /* disable suspend to make uninterrupted loading possible. */
        disable_suspend();
        /*
        * re-enable suspending after a minute. This is normally handled by a
        * plugin on onReaderReady(). However, if loading of the plugin fails
        * for some reason, suspension would stay inactive consuming a lot of
        * power
        */
        SetHardTimer("fallback_enable_suspend", fallback_enable_suspend, 1000 * 60);
    }

    if (type == EVT_POINTERDOWN) {
        touch_pointers = 1;
        genEmuEvent(inputfds[0], EV_ABS, ABS_MT_TRACKING_ID, 0);
        genEmuEvent(inputfds[0], EV_ABS, ABS_MT_POSITION_X, par1);
        genEmuEvent(inputfds[0], EV_ABS, ABS_MT_POSITION_Y, par2);
        //printf("****init slot0:%d %d\n", par1, par2);
    } else if (type == EVT_MTSYNC) {
        if (touch_pointers && (par2 == 2)) {
            if (gti && (mti = (*gti)())) {
                touch_pointers = par2;
                for (i = 0; i < touch_pointers; i++) {
                    //printf("****sync slot%d:%d %d\n", i, mti[i].x, mti[i].y);
                    //debug_mtinfo(&mti[i]);
                    genEmuEvent(inputfds[0], EV_ABS, ABS_MT_SLOT, i);
                    genEmuEvent(inputfds[0], EV_ABS, ABS_MT_TRACKING_ID, i);
                    genEmuEvent(inputfds[0], EV_ABS, ABS_MT_POSITION_X, mti[i].x);
                    genEmuEvent(inputfds[0], EV_ABS, ABS_MT_POSITION_Y, mti[i].y);
                    genEmuEvent(inputfds[0], EV_SYN, SYN_REPORT, 0);
                }
            }
        } else if (par2 == 0) {
            for (i = 0; i < 2; i++) {
                genEmuEvent(inputfds[0], EV_ABS, ABS_MT_SLOT, i);
                genEmuEvent(inputfds[0], EV_ABS, ABS_MT_TRACKING_ID, -1);
                genEmuEvent(inputfds[0], EV_SYN, SYN_REPORT, 0);
            }
        } else {
            genEmuEvent(inputfds[0], EV_SYN, SYN_REPORT, 0);
        }
    } else if (type == EVT_POINTERMOVE) {
        /* multi touch POINTERMOVE will be reported in EVT_MTSYNC
         * this will handle single touch POINTERMOVE only */
        if (touch_pointers == 1) {
            genEmuEvent(inputfds[0], EV_ABS, ABS_MT_POSITION_X, par1);
            genEmuEvent(inputfds[0], EV_ABS, ABS_MT_POSITION_Y, par2);
        }
    } else if (type == EVT_POINTERUP) {
        if (touch_pointers == 1) {
            genEmuEvent(inputfds[0], EV_ABS, ABS_MT_TRACKING_ID, -1);
        }
        touch_pointers = 0;
    } else if (type == EVT_KEYDOWN) {
        genEmuEvent(inputfds[0], EV_KEY, par1, 1);
    } else if (type == EVT_KEYREPEAT) {
        genEmuEvent(inputfds[0], EV_KEY, par1, 2);
    } else if (type == EVT_KEYUP) {
        genEmuEvent(inputfds[0], EV_KEY, par1, 0);
    } else if (type == EVT_BACKGROUND || type == EVT_FOREGROUND ||
               type == EVT_SHOW || type == EVT_HIDE ||
               type == EVT_EXIT) {
        /* Handle those as MiscEvent as this makes it easy to return a string directly,
         * which can be used in uimanager.lua as an event_handler index. */
        genEmuEvent(inputfds[0], EV_MSC, type, 0);
    } else if (type == PB_SPECIAL_SUSPEND) {
        external_suspend_control = 1;
        if (par1 == 0) {
            SetHardTimer("disable_suspend", disable_suspend, par2);
        } else {
            SetHardTimer("enable_suspend", enable_suspend, par2);
        }
    } else {
        genEmuEvent(inputfds[0], type, par1, par2);
    }
    return 0;
}

static void *runInkViewThread(void *arg) {
    InkViewMain(pb_event_handler);
    return 0;
}

static int startInkViewMain(lua_State *L, size_t fd_idx, const char *inputdevice) {
    pthread_t thread;
    pthread_attr_t thread_attr;

    inputfds[fd_idx] = open(inputdevice, O_RDWR | O_NONBLOCK);
    if (inputfds[fd_idx] == -1) {
        return luaL_error(L, "Error opening input device <%s>: %s", inputdevice, strerror(errno));
    }

    if (pthread_attr_init(&thread_attr) != 0) {
        return luaL_error(L, "Error initializing event listener thread attributes: %s", strerror(errno));
    }

    pthread_attr_setdetachstate(&thread_attr, PTHREAD_CREATE_DETACHED);
    if (pthread_create(&thread, &thread_attr, runInkViewThread, 0) == -1) {
        return luaL_error(L, "Error creating event listener thread: %s", strerror(errno));
    }
    pthread_attr_destroy(&thread_attr);
    return 0;
}

/* dummy generateFakeEvent function */
void generateFakeEvent(int pipefd[2]) { return; }

#endif
