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
 * the slot paramter to GetTouchInfo which returns only one iv_mtinfo for that slot. */
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

int touch_pointers = 0;
static int pb_event_handler(int type, int par1, int par2) {
    //printf("ev:%d %d %d\n", type, par1, par2);
    //fflush(stdout);
    int i;
    iv_mtinfo *mti;
    // general settings in only possible in forked process
    if (type == EVT_INIT) {
        SetPanelType(PANEL_DISABLED);
        get_gti_pointer();
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
    } else {
        genEmuEvent(inputfds[0], type, par1, par2);
    }
    return 0;
}

static int forkInkViewMain(lua_State *L, const char *inputdevice) {
    struct sigaction new_sa;
    int childpid;
    if ((childpid = fork()) == -1) {
        return luaL_error(L, "cannot fork() emu event listener");
    }
    if (childpid == 0) {
        /* we only use inputfds[0] in emu mode, because we only have one
         * fake device so far. */
        inputfds[0] = open(inputdevice, O_RDWR | O_NONBLOCK);
        if (inputfds < 0) {
            return luaL_error(L, "error opening input device <%s>: %d", inputdevice, errno);
        }
        InkViewMain(pb_event_handler);
        /* child will block in InkViewMain and never reach here */
        _exit(EXIT_SUCCESS);
    } else {
        /* InkViewMain will handle SIGINT in child and send EVT_EXIT event to
         * inputdevice. So it's safe for parent to ignore the signal */
        new_sa.sa_handler = SIG_IGN;
        new_sa.sa_flags = SA_RESTART;
        if (sigaction(SIGINT, &new_sa, NULL) == -1) {
            return luaL_error(L, "error setting up sigaction for SIGINT: %d", errno);
        }
        if (sigaction(SIGTERM, &new_sa, NULL) == -1) {
            return luaL_error(L, "error setting up sigaction for SIGTERM: %d", errno);
        }
    }
    return 0;
}

/* dummy generateFakeEvent function */
void generateFakeEvent(int pipefd[2]) { return; }

#endif
