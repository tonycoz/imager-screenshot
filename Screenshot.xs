#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "imext.h"
#include "imperl.h"
#include "imss.h"

DEFINE_IMAGER_CALLBACKS;

MODULE = Imager::Screenshot  PACKAGE = Imager::Screenshot PREFIX = imss_

PROTOTYPES: DISABLE

#ifdef SS_WIN32

Imager
imss_win32(hwnd, include_decor = 1)
	unsigned hwnd
	int include_decor

#endif

#ifdef SS_X11

Imager
imss_x11(window_id)
	int window_id

#endif

BOOT:
	PERL_INITIALIZE_IMAGER_CALLBACKS;