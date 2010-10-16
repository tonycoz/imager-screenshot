#include "svwin32.h"

SSHWND
hwnd_from_sv(pTHX_ SV *sv) {
  SvGETMAGIC(sv);

  if (SvPOK(sv)) {
    STRLEN len;
    char const *p = SvPV_nomg(sv, len);

    if (len == 6 && strEQ(p, "active")) {
      return (SSHWND)GetForegroundWindow();
    }
    else {
      return (SSHWND)NULL;
    }
  }

  return SvUV_nomg(sv);
}
