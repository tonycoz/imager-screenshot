#include "imext.h"
#include <windows.h>
#include <string.h>

i_img *
imss_win32(unsigned hwnd_u, int include_decor) {
  HWND hwnd = (HWND)hwnd_u;
  HDC wdc, bmdc;
  RECT rect;
  HBITMAP work_bmp, old_dc_bmp;
  int width, height;
  BITMAPINFO bmi;
  unsigned char *di_bits;
  i_img *result = NULL;

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

  width = rect.right - rect.left;
  height = rect.bottom - rect.top;
  work_bmp = CreateCompatibleBitmap(wdc, width, height);
  bmdc = CreateCompatibleDC(wdc);
  old_dc_bmp = SelectObject(bmdc, work_bmp);
  BitBlt(bmdc, 0, 0, width, height, wdc, 0, 0, SRCCOPY);

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

  /* clean up */
  myfree(di_bits);
  SelectObject(bmdc, old_dc_bmp);
  DeleteDC(bmdc);
  DeleteObject(work_bmp);
  ReleaseDC(hwnd, wdc);

  return result;
}
