/* handheld-inputd — volume/brightness key daemon for the RG35XX-H.
 *
 * Watches two evdev devices (without grabbing them, so RetroArch/SDL still
 * see every event):
 *   - "H700 Gamepad"      → FN button (BTN_MODE) held-state
 *   - "gpio-keys-volume"  → KEY_VOLUMEUP / KEY_VOLUMEDOWN
 *
 * Volume keys change the PipeWire default sink via pactl; with FN held they
 * step the panel backlight through sysfs instead.  Key repeat is generated
 * internally from held-state (kernel autorepeat events are ignored), so the
 * repeat rate is exact and works even if the DT lacks the autorepeat prop.
 *
 * The daemon sleeps in epoll between events — no polling, no subprocesses
 * except one pactl per volume step.
 */
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/input.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/epoll.h>
#include <sys/ioctl.h>
#include <time.h>
#include <unistd.h>

#ifndef PACTL
#error "compile with -DPACTL=\"/path/to/pactl\""
#endif

#define GAMEPAD_NAME   "H700 Gamepad"
#define VOLKEYS_NAME   "gpio-keys-volume"
#define FN_KEY         BTN_MODE     /* 316 */

#define REPEAT_DELAY_MS    400  /* hold time before repeat starts */
#define VOLUME_REPEAT_MS   250
#define BRIGHT_REPEAT_MS   200
#define BRIGHT_STEPS       10   /* backlight steps across full range */

static char bl_path[300];       /* /sys/class/backlight/<dev> */
static int  bl_max;

static long now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000L + ts.tv_nsec / 1000000L;
}

static int open_by_name(const char *want) {
    DIR *d = opendir("/dev/input");
    if (!d) return -1;
    struct dirent *e;
    int fd = -1;
    while ((e = readdir(d))) {
        if (strncmp(e->d_name, "event", 5)) continue;
        char path[288], name[64] = "";
        snprintf(path, sizeof path, "/dev/input/%s", e->d_name);
        int f = open(path, O_RDONLY | O_NONBLOCK | O_CLOEXEC);
        if (f < 0) continue;
        ioctl(f, EVIOCGNAME(sizeof name), name);
        if (!strcmp(name, want)) { fd = f; break; }
        close(f);
    }
    closedir(d);
    return fd;
}

static int find_backlight(void) {
    DIR *d = opendir("/sys/class/backlight");
    if (!d) return -1;
    struct dirent *e;
    while ((e = readdir(d))) {
        if (e->d_name[0] == '.') continue;
        char p[300];
        snprintf(p, sizeof p, "/sys/class/backlight/%s/max_brightness", e->d_name);
        FILE *f = fopen(p, "r");
        if (!f) continue;
        int ok = fscanf(f, "%d", &bl_max) == 1;
        fclose(f);
        if (ok && bl_max > 0) {
            snprintf(bl_path, sizeof bl_path, "/sys/class/backlight/%s", e->d_name);
            closedir(d);
            return 0;
        }
    }
    closedir(d);
    return -1;
}

/* Re-reads current brightness each time so external changes don't drift us. */
static void step_brightness(int dir) {
    char p[320];
    int cur = 0;
    snprintf(p, sizeof p, "%s/brightness", bl_path);
    FILE *f = fopen(p, "r");
    if (!f) return;
    if (fscanf(f, "%d", &cur) != 1) { fclose(f); return; }
    fclose(f);

    int step = bl_max / BRIGHT_STEPS;
    if (step < 1) step = 1;
    int new = cur + dir * step;
    if (new > bl_max) new = bl_max;
    if (new < 1) new = 1;   /* never fully off */
    f = fopen(p, "w");
    if (!f) return;
    fprintf(f, "%d", new);
    fclose(f);
}

static void step_volume(int dir) {
    pid_t pid = fork();
    if (pid == 0) {
        execl(PACTL, "pactl", "set-sink-volume", "@DEFAULT_SINK@",
              dir > 0 ? "+5%" : "-5%", (char *)NULL);
        _exit(127);
    }
}

static void act(int dir, int fn_held) {
    if (fn_held) step_brightness(dir);
    else         step_volume(dir);
}

/* Kernel-side event filtering (EVIOCSMASK): the gamepad streams analog-stick
 * EV_ABS events constantly during gameplay; without a mask every one of them
 * would wake us up just to be discarded.  Restrict this client to the FN key.
 * Best-effort — if the ioctl is unsupported we simply filter in userspace. */
static void mask_fn_only(int fd) {
    static uint8_t key_bits[(KEY_MAX + 7) / 8];
    static const uint8_t zero_bits[(KEY_MAX + 7) / 8];
    key_bits[FN_KEY / 8] = 1 << (FN_KEY % 8);
    struct input_mask m = {
        .type = EV_KEY,
        .codes_size = sizeof key_bits,
        .codes_ptr = (uintptr_t)key_bits,
    };
    ioctl(fd, EVIOCSMASK, &m);
    m.codes_ptr = (uintptr_t)zero_bits;
    for (int t = EV_REL; t <= EV_MSC; t++) {   /* EV_REL, EV_ABS, EV_MSC */
        if (t == EV_KEY) continue;
        m.type = t;
        ioctl(fd, EVIOCSMASK, &m);
    }
}

int main(void) {
    signal(SIGCHLD, SIG_IGN);   /* auto-reap pactl */

    int pad_fd = -1, vol_fd = -1;
    while (pad_fd < 0 || vol_fd < 0) {
        if (pad_fd < 0) pad_fd = open_by_name(GAMEPAD_NAME);
        if (vol_fd < 0) vol_fd = open_by_name(VOLKEYS_NAME);
        if (pad_fd < 0 || vol_fd < 0) sleep(1);
    }
    mask_fn_only(pad_fd);
    if (find_backlight() < 0)
        fprintf(stderr, "no backlight device; FN+volume disabled\n");

    int ep = epoll_create1(EPOLL_CLOEXEC);
    struct epoll_event ev = { .events = EPOLLIN };
    ev.data.fd = pad_fd; epoll_ctl(ep, EPOLL_CTL_ADD, pad_fd, &ev);
    ev.data.fd = vol_fd; epoll_ctl(ep, EPOLL_CTL_ADD, vol_fd, &ev);

    int fn_held = 0;
    int held_dir = 0;           /* -1 down, 0 none, +1 up */
    long next_repeat = 0;

    for (;;) {
        int timeout = -1;
        if (held_dir) {
            timeout = (int)(next_repeat - now_ms());
            if (timeout < 0) timeout = 0;
        }
        struct epoll_event out;
        int n = epoll_wait(ep, &out, 1, timeout);
        if (n < 0) {
            if (errno == EINTR) continue;
            return 1;
        }
        if (n == 0) {           /* repeat timer fired */
            if (held_dir) {
                act(held_dir, fn_held);
                next_repeat = now_ms() +
                    (fn_held ? BRIGHT_REPEAT_MS : VOLUME_REPEAT_MS);
            }
            continue;
        }

        struct input_event ie;
        for (;;) {
            ssize_t r = read(out.data.fd, &ie, sizeof ie);
            if (r != sizeof ie) {
                if (r < 0 && errno == EAGAIN) break;
                return 1;       /* device gone — systemd restarts us */
            }
            if (ie.type != EV_KEY || ie.value == 2) continue;  /* own repeat */
            switch (ie.code) {
            case FN_KEY:
                fn_held = ie.value;
                break;
            case KEY_VOLUMEUP:
            case KEY_VOLUMEDOWN: {
                int dir = ie.code == KEY_VOLUMEUP ? 1 : -1;
                if (ie.value == 1) {
                    held_dir = dir;
                    act(dir, fn_held);
                    next_repeat = now_ms() + REPEAT_DELAY_MS;
                } else if (held_dir == dir) {
                    held_dir = 0;
                }
                break;
            }
            }
        }
    }
}
