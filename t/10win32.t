#!perl -w
use strict;
use Test::More;

use Imager::Screenshot 'screenshot';

Imager::Screenshot->have_win32
    or plan skip_all => "No Win32 support";

plan tests => 2;

{
  my $im = screenshot(hwnd => 0);
  
  ok($im, "got a screenshot");
}

{ # as a method
  my $im = Imager::Screenshot->screenshot(hwnd => 0);

  ok($im, "call as a method");
}

