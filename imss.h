#ifndef IMSS_H
#define IMSS_H

extern i_img *
imss_win32(unsigned hwnd, int include_decor);

extern i_img *
imss_x11(unsigned long display, int window_id);

extern unsigned long
imss_x11_open(char const *display_name);
extern void
imss_x11_close(unsigned long display);

#endif
