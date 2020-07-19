#include <linux/input.h>
#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <stdbool.h>

static double timespec_diff(struct timespec const* start, struct timespec const* end)
{
    double s = difftime(end->tv_sec, (double)start->tv_sec);
    double ns = (double)end->tv_nsec - (double)start->tv_nsec;
    return s + (ns / 1e9);
}

int main(int argc, char** argv)
{
    FILE* evf = fopen("/dev/input/event2", "rb");
    if(!evf) {
        fprintf(stderr, "Could not open /dev/input/event2\n");
        return 1;
    }

    struct input_event ev;
    struct timespec press_time = {0};
    bool pressed = false;
    while(1) {
        size_t sz = fread(&ev, sizeof(ev), 1, evf);
        if(sz == 0) {
            return 1;
        }
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
