#include <linux/input.h>
#include <stdio.h>
#include <time.h>
#include <stdlib.h>

static double timeval_diff(struct timeval const* start, struct timeval const* end)
{
    double s = (double)end->tv_sec - (double)start->tv_sec;
    double us = (double)end->tv_usec - (double)start->tv_usec;
    return s + (us / 1e6);
}

int main(int argc, char** argv)
{
    FILE* evf = fopen("/dev/input/event2", "rb");
    if(!evf) {
        fprintf(stderr, "Could not open /dev/input/event2\n");
        return 1;
    }

    struct input_event ev;
    struct timeval press_stamp = {0};
    while(1) {
        size_t sz = fread(&ev, sizeof(ev), 1, evf);
        if(sz == 0) {
            return 1;
        }
        if(ev.type == EV_KEY && ev.code == KEY_HOME) {
            if(ev.value == 0) { /* keyrelease */
                double t = timeval_diff(&press_stamp, &ev.time);
                /* hold home (middle) button for 3 seconds to start koreader */
                if(t >= 3.0) {
                    system("systemctl start koreader");
                }
            }
            else if(ev.value == 1) { /* keypress */
                press_stamp = ev.time;
            }
        }
    }
}
