#include "imext.h"
#include <windows.h>
#include <string.h>
#include "imss.h"

i_img *
imss_win32(unsigned hwnd_u, int include_decor, int left, int top, 
	   int right, int bottom) {
  HWND hwnd = (HWND)hwnd_u;
  HDC wdc, bmdc;
  RECT rect;
  HBITMAP work_bmp, old_dc_bmp;
  int window_width, window_height;
  BITMAPINFO bmi;
  unsigned char *di_bits;
  i_img *result = NULL;
  int width, height;

  i_clear_error();

  if (!hwnd)
    hwnd = GetDesktopWindow();

  if (include_decor) {
    wdc = GetWindowDC(hwnd);
    GetWindowRect(hwnd, &rect);
  }
  else {
    wdc = GetDC(hwnd);
    GetClientRect(hwnd, &rect);
  }
  if (!wdc) {
    i_push_error(0, "Cannot get window DC - invalid hwnd?");
    return NULL;
  }

  window_width = rect.right - rect.left;
  window_height = rect.bottom - rect.top;

  /* adjust negative/zero values to window size */
  if (left < 0)
    left += window_width;
  if (top < 0)
    top += window_height;
  if (right <= 0)
    right += window_width;
  if (bottom <= 0)
    bottom += window_height;
  
  /* clamp */
  if (left < 0)
    left = 0;
  if (right > window_width)
    right = window_width;
  if (top < 0)
    top = 0;
  if (bottom > window_height)
    bottom = window_height;

  /* validate */
  if (right <= left || bottom <= top) {
    i_push_error(0, "image would be empty");
    return NULL;
  }
  width = right - left;
  height = bottom - top;

  work_bmp = CreateCompatibleBitmap(wdc, width, height);
  bmdc = CreateCompatibleDC(wdc);
  old_dc_bmp = SelectObject(bmdc, work_bmp);
  BitBlt(bmdc, 0, 0, width, height, wdc, left, top, SRCCOPY);

  /* make a dib */
  memset(&bmi, 0, sizeof(bmi));
  bmi.bmiHeader.biSize = sizeof(bmi);
  bmi.bmiHeader.biWidth = width;
  bmi.bmiHeader.biHeight = -height;
  bmi.bmiHeader.biPlanes = 1;
  bmi.bmiHeader.biBitCount = 32;
  bmi.bmiHeader.biCompression = BI_RGB;

  di_bits = mymalloc(4 * width * height);
  if (GetDIBits(bmdc, work_bmp, 0, height, di_bits, &bmi, DIB_RGB_COLORS)) {
    i_color *line = mymalloc(sizeof(i_color) * width);
    i_color *cp;
    int x, y;
    unsigned char *ch_pp = di_bits;
    result = i_img_8_new(width, height, 3);

    for (y = 0; y < height; ++y) {
      cp = line;
      for (x = 0; x < width; ++x) {
	cp->rgb.b = *ch_pp++;
	cp->rgb.g = *ch_pp++;
	cp->rgb.r = *ch_pp++;
	ch_pp++;
	cp++;
      }
      i_plin(result, 0, width, y, line);
    }
    myfree(line);
  }

  i_tags_setn(&result->tags, "ss_window_width", window_width);
  i_tags_setn(&result->tags, "ss_window_height", window_height);
  i_tags_set(&result->tags, "ss_type", "Win32", 5);
  i_tags_setn(&result->tags, "ss_left", left);
  i_tags_setn(&result->tags, "ss_top", top);

  /* clean up */
  myfree(di_bits);
  SelectObject(bmdc, old_dc_bmp);
  DeleteDC(bmdc);
  DeleteObject(work_bmp);
  ReleaseDC(hwnd, wdc);

  return result;
}
