#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "imext.h"
#include "imperl.h"
#include "imss.h"

DEFINE_IMAGER_CALLBACKS;

#define imss__x11_open imss_x11_open

MODULE = Imager::Screenshot  PACKAGE = Imager::Screenshot PREFIX = imss

PROTOTYPES: DISABLE

#ifdef SS_WIN32

Imager
imss_win32(hwnd, include_decor = 0)
	unsigned hwnd
	int include_decor

#endif

#ifdef SS_X11

Imager
imss_x11(display, window_id)
        unsigned long display
	int window_id

unsigned long
imss_x11_open(display_name = NULL)
        const char *display_name

void
imss_x11_close(display)
        unsigned long display

#endif

BOOT:
	PERL_INITIALIZE_IMAGER_CALLBACKS;