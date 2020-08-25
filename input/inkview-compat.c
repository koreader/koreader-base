#include <pthread.h>
#include <semaphore.h>
#include "inkview.h"

#define COMPAT __attribute__((weak))
#define TICK_MS 20

static int abc[3];
static pthread_t ivm_thread;
static sem_t sem_notify, sem_poll;
static iv_handler handler;
static iv_mtinfo *gtcache;
static int exiting;

static void poll_timer() {
    SetWeakTimer("compat-poll", poll_timer, TICK_MS); // re-arm
    abc[0] = -1; // signals expiry
    sem_post(&sem_notify);
    sem_wait(&sem_poll);
}

static int ivm_proc(int a, int b, int c) {
    if (a == EVT_INIT) {
        SetWeakTimer("compat-poll", poll_timer, TICK_MS);
        sem_wait(&sem_poll);
    }
    abc[0] = a;
    abc[1] = b;
    abc[2] = c;
    if (a == EVT_EXIT) {
        exiting = 1;
    } else if (exiting) return 2;
    sem_post(&sem_notify);
    sem_wait(&sem_poll);
    return 0;
}

COMPAT void PrepareForLoop(iv_handler h) {
    handler = h;
    sem_init(&sem_notify, 0, 0);;
    sem_init(&sem_poll, 0, 0);;
    pthread_create(&ivm_thread, NULL, (void *)&InkViewMain, ivm_proc);
}

COMPAT void ProcessEventLoop() {
    sem_post(&sem_poll);
    sem_wait(&sem_notify);
    if (abc[0] != -1)
        handler(abc[0], abc[1], abc[2]);
}

COMPAT void ClearOnExit() {
    ClearTimer(poll_timer);
    if (!exiting) {
        LeaveInkViewMain();
        exiting = 1;
    }
    sem_post(&sem_poll);
    sem_post(&sem_poll);
    pthread_join(ivm_thread, NULL); // until it escapes IVM
    sem_destroy(&sem_notify);
    sem_destroy(&sem_poll);
}

COMPAT iv_mtinfo *GetTouchInfoI(unsigned int i) {
    if (!i) gtcache = GetTouchInfo();
    return gtcache + i;
}

