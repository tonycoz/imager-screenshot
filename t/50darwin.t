#!perl -w
use strict;
use Test::More;

use Imager::Screenshot 'screenshot';

++$|;

Imager::Screenshot->have_darwin
  or plan skip_all => "No darwin support";

my $im = screenshot(darwin => 0, right => 1, bottom => 1);
unless ($im) {
  my $err = Imager->errstr;
  $err =~ /No pixel format found/
    or plan skip_all => "Probably an inactive user";
  $err =~ /No main display/
    or plan skip_all => "User doen't have a display";
}

plan tests => 7;

{
  my $im = screenshot(darwin => 0);
  ok($im, "got an image");
  is($im->getchannels, 3, "we have some color");

  is($im->tags(name => "ss_window_width"), $im->getwidth,
     "check ss_window_width tag");
  is($im->tags(name => 'ss_window_height'), $im->getheight,
     "check ss_window_height tag");
  is($im->tags(name => 'ss_left'), 0, "check ss_left tag");
  is($im->tags(name => 'ss_top'), 0, "check ss_top tag");
  is($im->tags(name => 'ss_type'), 'Darwin', "check ss_type tag");
}
