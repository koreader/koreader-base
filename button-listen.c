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

static bool open_file(FILE **evf, fd_set* fd_set, const char *filename)
{
    FILE *file = NULL;
    int fd = -1;
    file = fopen(filename, "rb");
    if(!file) {
        fprintf(stderr, "Could not open %s\n", filename);
        return false;
    }
    fd = fileno(file);
    printf("Opened fd %d for %s\n", fd, filename);
    if (fd < 0 || fd >= FD_SETSIZE) {
        fprintf(stderr, "File descriptor for %s too large to handle (%d > %d)", filename, fd, FD_SETSIZE);
        return false;
    }
    evf[fd] = file;
    FD_SET(fd, fd_set);
    return true;
}

int main(int argc, char** argv)
{
    FILE *evf[FD_SETSIZE];
    fd_set evf_set;
    FD_ZERO(&evf_set);
    if(!open_file(evf, &evf_set, "/dev/input/event2")) {
        return 1;
    }
    open_file(evf, &evf_set, "/dev/input/event1");
    struct input_event ev;
    struct timespec press_time = {0};
    bool pressed = false;
    while(1) {
        if(select(FD_SETSIZE, &evf_set, NULL, NULL, NULL) < 0){
            fprintf(stderr, "Failure in reading input event: %s\n", strerror(errno));
            return 1;
        }
        printf("Waking...");fflush(stdout);
        for (int i = 0; i < FD_SETSIZE; i++){
            if(FD_ISSET(i, &evf_set)){
                printf("Reading data %d of %d...", i, FD_SETSIZE); fflush(stdout);
                size_t sz = fread(&ev, sizeof(ev), 1, evf[i]);
                printf("Read data\n"); fflush(stdout);
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
