#!perl -w
use strict;
use Test::More tests => 1;

use Imager::Screenshot 'screenshot';

Imager::Screenshot->have_win32
    or skip_all("No Win32 support");

my $im = screenshot(hwnd => 0);

ok($im, "got a screenshot");
$im->write(file => "foo.ppm");
