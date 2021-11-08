#include <linux/input.h>
#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <stdbool.h>
#include <sys/types.h>
#include <string.h>
#include <errno.h>

static double timespec_diff(struct timespec const* start, struct timespec const* end)
{
    double s = difftime(end->tv_sec, (double)start->tv_sec);
    double ns = (double)end->tv_nsec - (double)start->tv_nsec;
    return s + (ns / 1e9);
}

int main(int argc, char** argv)
{
    FILE *evf[2];
    fd_set evf_set;
    FD_ZERO(&evf_set);
    // Read from event2 if pre-firmware update
    evf[0] = fopen("/dev/input/event2", "rb");
    if(!evf[0]) {
        fprintf(stderr, "Could not open /dev/input/event2\n");
        return 1;
    }
    FD_SET(fileno(evf[0]), &evf_set);
    // Read from event1 if post-fireware update
    evf[1] = fopen("/dev/input/event1", "rb");
    if(!evf[1]) {
        fprintf(stderr, "Could not open /dev/input/event1\n. Only required post firmware update, so non-fatal.");
    }else {
        FD_SET(fileno(evf[1]), &evf_set);
    }
    struct input_event ev;
    struct timespec press_time = {0};
    bool pressed = false;
    while(1) {
        if(select(FD_SETSIZE, &evf_set, NULL, NULL, NULL) < 0){
            fprintf(stderr, "Failure in reading input event: %s\n", strerror(errno));
            return 1;
        }
        for (int i = 0; i < FD_SETSIZE; i++){
            if(FD_ISSET(i, &evf_set)){
                size_t sz = fread(&ev, sizeof(ev), 1, evf[i]);
                if(sz == 0) {
                    return 1;
                }
                // Ensure that it is a button press, not a touch event.
                if(ev.type == EV_KEY && ev.code == KEY_HOME) {
                    if(ev.value == 0 && pressed) { /* keyrelease */
                        struct timespec now;
                        clock_gettime(CLOCK_BOOTTIME, &now);
                        double t = timespec_diff(&press_time, &now);
                        /* Require a press event before processing another release */
                        pressed = false;
                        /* hold home (middle) button for 3 seconds to start koreader */
                        if(t >= 3.0) {
                            system("systemctl start koreader");
                        }
                    }
                    else if(ev.value == 1) { /* keypress */
                        clock_gettime(CLOCK_BOOTTIME, &press_time);
                        pressed = true;
                    }
                }
            }
        }
    }
}
