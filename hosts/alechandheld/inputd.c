/* handheld-inputd — volume/brightness key daemon for the RG35XX-H.
 *
 * Grabs the physical "H700 Gamepad" and forwards its events through a uinput
 * clone (same name/IDs, so SDL mappings and RetroArch bindings are identical).
 * Forwarding exists so the FN button can be intercepted:
 *
 *   - FN + volume key      → backlight step; FN is NEVER forwarded, so the
 *                            game/RetroArch don't react to it
 *   - FN tap (nothing else) → forwarded as a press+release on FN release
 *                            (RetroArch menu toggle keeps working)
 *   - FN + gamepad button  → FN press is forwarded just-in-time before the
 *                            button (RetroArch hotkey combos keep working)
 *
 * "gpio-keys-volume" is watched without grabbing.  Volume keys change the
 * PipeWire default sink via pactl; with FN held they step the backlight
 * through sysfs.  Key repeat is generated internally (kernel autorepeat
 * events are ignored) so the rate is exact.
 *
 * The daemon sleeps in epoll between events; the only subprocess is one
 * pactl per volume step.
 */
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <linux/input.h>
#include <linux/uinput.h>
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
#define FN_TAP_HOLD_MS     300  /* replayed FN tap: hold this long.  RetroArch
                                   ignores the hotkey-enable button until it has
                                   been held input_hotkey_block_delay (5) frames,
                                   which is 167ms in a 30fps core — stay well
                                   above that or a lone tap never registers */

static char bl_path[300];       /* /sys/class/backlight/<dev> */
static int  bl_max;
static int  uinput_fd = -1;

static long now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000L + ts.tv_nsec / 1000000L;
}

/* The clone shares the physical device's name, so skip /devices/virtual/
 * nodes or we would grab our own output after a restart. */
static int is_virtual(const char *evname) {
    char link[288], resolved[PATH_MAX];
    snprintf(link, sizeof link, "/sys/class/input/%s", evname);
    if (!realpath(link, resolved)) return 0;
    return strstr(resolved, "/devices/virtual/") != NULL;
}

static int open_by_name(const char *want) {
    DIR *d = opendir("/dev/input");
    if (!d) return -1;
    struct dirent *e;
    int fd = -1;
    while ((e = readdir(d))) {
        if (strncmp(e->d_name, "event", 5)) continue;
        if (is_virtual(e->d_name)) continue;
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

/* uinput clone of the physical gamepad: same key/abs capabilities and name,
 * but zeroed input_id.  The distinct SDL GUID lets the PortMaster env map the
 * clone alone and ignore the physical device (SDL's bundled controller DB has
 * an entry for the Anbernic VID/PID with the wrong layout, and games that saw
 * both devices sometimes bound the grabbed, dead one). */
static int create_clone(int src) {
    int u = open("/dev/uinput", O_WRONLY | O_NONBLOCK | O_CLOEXEC);
    if (u < 0) return -1;

    unsigned char bits[(KEY_MAX + 7) / 8];
    memset(bits, 0, sizeof bits);
    ioctl(src, EVIOCGBIT(EV_KEY, sizeof bits), bits);
    ioctl(u, UI_SET_EVBIT, EV_KEY);
    for (int c = 0; c <= KEY_MAX; c++)
        if (bits[c / 8] >> (c % 8) & 1) ioctl(u, UI_SET_KEYBIT, c);

    memset(bits, 0, sizeof bits);
    if (ioctl(src, EVIOCGBIT(EV_ABS, (ABS_MAX + 7) / 8), bits) >= 0) {
        int any = 0;
        for (int c = 0; c <= ABS_MAX; c++) {
            if (!(bits[c / 8] >> (c % 8) & 1)) continue;
            if (!any) { ioctl(u, UI_SET_EVBIT, EV_ABS); any = 1; }
            struct uinput_abs_setup as = { .code = c };
            ioctl(src, EVIOCGABS(c), &as.absinfo);
            ioctl(u, UI_ABS_SETUP, &as);
        }
    }

    struct uinput_setup us;
    memset(&us, 0, sizeof us);   /* id stays all-zero on purpose, see above */
    strncpy(us.name, GAMEPAD_NAME, sizeof us.name - 1);
    if (ioctl(u, UI_DEV_SETUP, &us) < 0 || ioctl(u, UI_DEV_CREATE) < 0) {
        close(u);
        return -1;
    }
    return u;
}

static void emit(unsigned short type, unsigned short code, int value) {
    struct input_event e;
    memset(&e, 0, sizeof e);
    e.type = type; e.code = code; e.value = value;
    if (write(uinput_fd, &e, sizeof e) < 0) { /* clone gone: restart */ }
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

int main(void) {
    signal(SIGCHLD, SIG_IGN);   /* auto-reap pactl */

    /* pactl needs these to reach the PipeWire-pulse socket; the UID is not
     * stable across installs, so derive the runtime dir instead of
     * hardcoding it in the service definition. */
    char rt[64], ps[96];
    snprintf(rt, sizeof rt, "/run/user/%u", (unsigned)getuid());
    snprintf(ps, sizeof ps, "unix:%s/pulse/native", rt);
    setenv("XDG_RUNTIME_DIR", rt, 1);
    setenv("PULSE_SERVER", ps, 1);

    int pad_fd = -1, vol_fd = -1;
    while (pad_fd < 0 || vol_fd < 0) {
        if (pad_fd < 0) pad_fd = open_by_name(GAMEPAD_NAME);
        if (vol_fd < 0) vol_fd = open_by_name(VOLKEYS_NAME);
        if (pad_fd < 0 || vol_fd < 0) sleep(1);
    }

    uinput_fd = create_clone(pad_fd);
    if (uinput_fd < 0) { fprintf(stderr, "uinput clone failed\n"); return 1; }
    if (ioctl(pad_fd, EVIOCGRAB, 1) < 0) {
        fprintf(stderr, "cannot grab gamepad\n");
        return 1;
    }
    if (find_backlight() < 0)
        fprintf(stderr, "no backlight device; FN+volume disabled\n");

    int ep = epoll_create1(EPOLL_CLOEXEC);
    struct epoll_event ev = { .events = EPOLLIN };
    ev.data.fd = pad_fd; epoll_ctl(ep, EPOLL_CTL_ADD, pad_fd, &ev);
    ev.data.fd = vol_fd; epoll_ctl(ep, EPOLL_CTL_ADD, vol_fd, &ev);

    int fn_held = 0;        /* FN physically down */
    int fn_used = 0;        /* FN consumed as a brightness modifier */
    int fn_forwarded = 0;   /* FN press already sent to the clone */
    long fn_tap_release = 0;/* when to release a replayed FN tap (0 = none) */
    int held_dir = 0;       /* volume key held: -1 down, 0 none, +1 up */
    long next_repeat = 0;

    for (;;) {
        int timeout = -1;
        long now = now_ms();
        if (held_dir) {
            long t = next_repeat - now;
            timeout = t < 0 ? 0 : (int)t;
        }
        if (fn_tap_release) {
            long t = fn_tap_release - now;
            if (t < 0) t = 0;
            if (timeout < 0 || t < timeout) timeout = (int)t;
        }
        struct epoll_event out;
        int n = epoll_wait(ep, &out, 1, timeout);
        if (n < 0) {
            if (errno == EINTR) continue;
            return 1;
        }
        if (n == 0) {           /* a timer fired */
            now = now_ms();
            if (fn_tap_release && now >= fn_tap_release) {
                emit(EV_KEY, FN_KEY, 0);
                emit(EV_SYN, SYN_REPORT, 0);
                fn_tap_release = 0;
            }
            if (held_dir && now >= next_repeat) {
                if (fn_held) { fn_used = 1; step_brightness(held_dir); }
                else         step_volume(held_dir);
                next_repeat = now +
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

            if (out.data.fd == vol_fd) {
                /* ungrabbed; we only act, never forward */
                if (ie.type != EV_KEY || ie.value == 2) continue;
                if (ie.code != KEY_VOLUMEUP && ie.code != KEY_VOLUMEDOWN) continue;
                int dir = ie.code == KEY_VOLUMEUP ? 1 : -1;
                if (ie.value == 1) {
                    held_dir = dir;
                    if (fn_held) { fn_used = 1; step_brightness(dir); }
                    else         step_volume(dir);
                    next_repeat = now_ms() + REPEAT_DELAY_MS;
                } else if (held_dir == dir) {
                    held_dir = 0;
                }
                continue;
            }

            /* gamepad: FN interception, everything else forwarded verbatim */
            if (ie.type == EV_KEY && ie.code == FN_KEY) {
                if (ie.value == 1) {
                    /* flush a still-pending replayed tap before a new press */
                    if (fn_tap_release) {
                        emit(EV_KEY, FN_KEY, 0);
                        emit(EV_SYN, SYN_REPORT, 0);
                        fn_tap_release = 0;
                    }
                    fn_held = 1; fn_used = 0; fn_forwarded = 0;
                } else if (ie.value == 0) {
                    fn_held = 0;
                    if (fn_forwarded) {
                        emit(EV_KEY, FN_KEY, 0);
                        emit(EV_SYN, SYN_REPORT, 0);
                        fn_forwarded = 0;
                    } else if (!fn_used) {
                        /* plain tap: replay the press and hold it briefly —
                         * an instant press+release lands within one frame and
                         * RetroArch's per-frame sampling never sees it */
                        emit(EV_KEY, FN_KEY, 1);
                        emit(EV_SYN, SYN_REPORT, 0);
                        fn_tap_release = now_ms() + FN_TAP_HOLD_MS;
                    }
                }
                continue;
            }
            /* another button while FN is pending → it's a hotkey combo:
             * send the deferred FN press first */
            if (ie.type == EV_KEY && ie.value == 1 &&
                fn_held && !fn_forwarded && !fn_used) {
                emit(EV_KEY, FN_KEY, 1);
                emit(EV_SYN, SYN_REPORT, 0);
                fn_forwarded = 1;
            }
            if (write(uinput_fd, &ie, sizeof ie) < 0 && errno != EAGAIN)
                return 1;
        }
    }
}
