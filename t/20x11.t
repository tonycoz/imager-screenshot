#!perl -w
use strict;
use Test::More;

use Imager::Screenshot 'screenshot';

Imager::Screenshot->have_x11
    or plan skip_all => "No X11 support";

# can we connect to a display
my $display = Imager::Screenshot::x11_open()
  or plan skip_all => "Cannot connect to a display: ".Imager->errstr;

plan tests => 5;

{
  # should automatically connect and grab the root window
  my $im = screenshot(id => 0)
    or print "# ", Imager->errstr, "\n";
  
  ok($im, "got a root screenshot, no display");
}

{
  # use our supplied display
  my $im = screenshot(display => $display, id => 0);
  ok($im, "got a root screenshot, supplied display");
}

{
  # use our supplied display - as a method
  my $im = Imager::Screenshot->screenshot(display => $display, id => 0);
  ok($im, "got a root screenshot, supplied display (method)");
}

{
  # supply a junk window id
  my $im = screenshot(display => $display, id => 0xFFFFFFF)
    or print "# ", Imager->errstr, "\n";
  ok(!$im, "should fail to get screenshot");
  cmp_ok(Imager->errstr, '=~', 'BadWindow',
         "check error");
}

Imager::Screenshot::x11_close($display);
