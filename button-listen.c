#include <errno.h>
#include <linux/input.h>
#include <poll.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static double timespec_diff(struct timespec const* start, struct timespec const* end)
{
    double s  = difftime(end->tv_sec, (double) start->tv_sec);
    double ns = (double) end->tv_nsec - (double) start->tv_nsec;
    return s + (ns / 1e9);
}

static bool open_file(FILE** evf, struct pollfd* evf_poll, int file_idx, int expected_files, const char* filename)
{
    if (file_idx < 0 || file_idx >= expected_files) {
        fprintf(stderr, "Attempted to add file index %d, but only %d files are supported", file_idx, expected_files);
        return false;
    }
    FILE* file = NULL;
    int   fd   = -1;
    file       = fopen(filename, "re");
    if (!file) {
        fprintf(stderr, "Could not open %s\n", filename);
        return false;
    }
    fd                    = fileno(file);
    evf[file_idx]         = file;
    evf_poll[file_idx].fd = fd;
    return true;
}

int main(int argc, char** argv)
{
    int           num_input_files = 2;
    FILE*         evf[num_input_files];
    struct pollfd evf_poll[num_input_files];
    for (int i = 0; i < num_input_files; i++) {
        evf[i]              = NULL;
        evf_poll[i].fd      = -1;
        evf_poll[i].events  = POLLIN;
        evf_poll[i].revents = 0;
    }
    if (!open_file(evf, evf_poll, 0, num_input_files, "/dev/input/event2")) {
        return 1;
    }
    open_file(evf, evf_poll, 1, num_input_files, "/dev/input/event1");
    struct input_event ev;
    struct timespec    press_time = { 0 };
    bool               pressed    = false;
    while (1) {
        if (poll(evf_poll, num_input_files, -1) < 0) {
            fprintf(stderr, "Failure in reading input event: %s\n", strerror(errno));
            return 1;
        }
        for (int i = 0; i < num_input_files; i++) {
            if (evf_poll[i].revents & POLLIN) {
                size_t sz = fread(&ev, sizeof(ev), 1, evf[i]);
                if (sz == 0) {
                    return 1;
                }
                // Ensure that it is a button press, not a touch event.
                if (ev.type == EV_KEY && ev.code == KEY_HOME) {
                    if (ev.value == 0 && pressed) { /* keyrelease */
                        struct timespec now;
                        clock_gettime(CLOCK_BOOTTIME, &now);
                        double t = timespec_diff(&press_time, &now);
                        /* Require a press event before processing another release */
                        pressed = false;
                        /* hold home (middle) button for 3 seconds to start koreader */
                        if (t >= 3.0) {
                            system("systemctl start koreader");
                        }
                    } else if (ev.value == 1) { /* keypress */
                        clock_gettime(CLOCK_BOOTTIME, &press_time);
                        pressed = true;
                    }
                }
            }
            if (evf_poll[i].revents & (POLLERR | POLLHUP | POLLNVAL)) {
                fprintf(stderr, "Stream may have been closed for input file");
            }
            evf_poll[i].revents = 0;
        }
    }
}
