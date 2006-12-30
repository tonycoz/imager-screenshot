#include "imext.h"
#include <X11/Xlib.h>

static
int
my_handler(Display *display, XErrorEvent *error) {
  char buffer[500];

  XGetErrorText(display, error->error_code, buffer, sizeof(buffer));
  i_push_error(error->error_code, buffer);
}

i_img *
imss_x11(unsigned long display_ul, unsigned long window_id) {
  Display *display = (Display *)display_ul;
  int own_display = 0; /* non-zero if we connect */
  GC gc;
  XImage *image;
  XWindowAttributes attr;
  i_img *result;
  i_color *line, *cp;
  int x, y;
  XColor *colors;
  XErrorHandler old_handler;

  i_clear_error();

  /* we don't want the default noisy error handling */
  old_handler = XSetErrorHandler(my_handler);

  if (!display) {
    display = XOpenDisplay(NULL);
    ++own_display;
    if (!display) {
      XSetErrorHandler(old_handler);
      i_push_error(0, "No display supplied and cannot connect");
      return NULL;
    }
  }

  if (!window_id) {
    int screen = DefaultScreen(display);
    window_id = RootWindow(display, 0);
  }

  if (!XGetWindowAttributes(display, window_id, &attr)) {
    XSetErrorHandler(old_handler);
    if (own_display)
      XCloseDisplay(display);
    i_push_error(0, "Cannot XGetWindowAttributes");
    return NULL;
  }

  image = XGetImage(display, window_id, 0, 0, attr.width, attr.height,
                    -1, ZPixmap);
  if (!image) {
    XSetErrorHandler(old_handler);
    if (own_display)
      XCloseDisplay(display);
    i_push_error(0, "Cannot XGetImage");
    return NULL;
  }

  result = i_img_8_new(attr.width, attr.height, 3);
  line = mymalloc(sizeof(i_color) * attr.width);
  colors = mymalloc(sizeof(XColor) * attr.width);
  for (y = 0; y < attr.height; ++y) {
    cp = line;
    /* XQueryColors seems to be a round-trip, so do one big request
       instead of one per pixel */
    for (x = 0; x < attr.width; ++x) {
      colors[x].pixel = XGetPixel(image, x, y);
    }
    XQueryColors(display, attr.colormap, colors, attr.width);
    for (x = 0; x < attr.width; ++x) {
      cp->rgb.r = colors[x].red >> 8;
      cp->rgb.g = colors[x].green >> 8;
      cp->rgb.b = colors[x].blue >> 8;
      ++cp;
    }
    i_plin(result, 0, attr.width, y, line);
  }

  XSetErrorHandler(old_handler);
  if (own_display)
    XCloseDisplay(display);

  return result;
}

unsigned long
imss_x11_open(char const *display_name) {
  XErrorHandler old_handler;
  Display *display;

  i_clear_error();
  XSetErrorHandler(my_handler);
  display = XOpenDisplay(display_name);
  if (!display)
    i_push_errorf(0, "Cannot connect to X server %s", XDisplayName(display_name));
  
  XSetErrorHandler(old_handler);

  return (unsigned long)display;
}

void
imss_x11_close(unsigned long display) {
  XCloseDisplay((Display *)display);
}
