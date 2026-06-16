#include <stdbool.h>
#include <gtk/gtk.h>

#define HEIGHT      700
#define FULL_WIDTH  800
#define WIDTH       FULL_WIDTH
#define BAR_WIDTH   250

#define ZOOM_START_LEVEL 1.0
#define ZOOM_STEPSIZE .1
#define MAX_NUM_TABS 8 // false for inf tabs
#define SEARCH "https://bing.com/search?q=%s"
#define HOME "file:///home/alec/.config/vimb/homepage.html"

/* Plugins */
#define LIBRE_REDIRECT_ENABLED false
#define READABILITY_ENABLED false
#define CUSTOM_USER_AGENT false
#define ADBLOCK_ENABLED true
#define ADBLOCK_EXTENSIONS_DIR "@out@/share/rosenrot/extensions"
#define ADBLOCK_FILTERLIST_PATH "@out@/share/rosenrot/easylist.txt"

#define WEBKIT_DEFAULT_SETTINGS \
    "enable-developer-extras", true, \
    "allow-modal-dialogs", true, \
    "enable-encrypted-media", true, \
    "enable-media-capabilities", true, \
    "enable-media-stream", true, \
    "enable-smooth-scrolling", true, \
    "default-charset", "utf-8"

#define DATA_DIR "/home/alec/.cache/rosenrot"
#define DATA_MANAGER_OPTS "base-cache-directory", DATA_DIR, "base-data-directory", DATA_DIR
#define NETWORK_SESSION_OPTS DATA_DIR, DATA_DIR

#define GTK_SETTINGS_CONFIG_H "gtk-enable-animations", true
#define KEY(x) GDK_KEY_##x
#define SFT  1 << 0
#define CTRL 1 << 2
#define ALT  1 << 3
#define BACKTICK 96

/* Misc helpers */
#define ABORT_REQUEST_ON_CURRENT_TAB NULL
#define NULLCHECK(x)                                   \
    do {                                               \
        if (x == NULL) {                               \
            printf("\nNULL check not passed");         \
            printf("@ %s (%d): ", __FILE__, __LINE__); \
            exit(0);                                   \
        }                                              \
    } while (0)

/* keybinds */
typedef enum {
    goback,
    goforward,

    refresh,
    refresh_force,

    toggle_fullscreen,

    zoomin,
    zoomout,
    zoom_reset,

    new_tab,
    next_tab,
    prev_tab,
    close_tab,

    show_searchbar,
    hide_bar,
    show_finder,
    finder_next,
    finder_prev,
    filter,

    toggle_custom_style,
    back_to_home,
    halve_window,
    rebig_window,
    prettify,
    save_uri_to_txt,
    open_uri_in_brave,
} func;

static struct {
    unsigned mod;
    unsigned key;
    func id;
} shortcut[] = {
    { CTRL,        KEY(h),             goback               },
    { CTRL,        KEY(j),             goforward            },

    { CTRL,        KEY(r),             refresh              },
    { CTRL,        KEY(R),             refresh_force        },

    { 0x0,         KEY(F11),           toggle_fullscreen    },

    { CTRL,        KEY(equal),         zoomin               },
    { CTRL,        KEY(minus),         zoomout              },
    { CTRL,        KEY(0),             zoom_reset           },

    { CTRL,        KEY(Tab),           next_tab             },
    { ALT,         KEY(Tab),           prev_tab             },
    { CTRL,        KEY(t),             new_tab              },
    { CTRL,        KEY(w),             close_tab            },

    { CTRL,        KEY(l),             show_searchbar       },
    { CTRL,        KEY(o),             hide_bar             },
    { CTRL,        KEY(f),             show_finder          },
    { CTRL,        KEY(n),             finder_next          },
    { CTRL,        KEY(N),             finder_prev          },
    { CTRL,        KEY(F),             filter               },
    { CTRL,        KEY(s),             save_uri_to_txt      },
};
