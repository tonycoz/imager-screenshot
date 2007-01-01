#!perl -w
use strict;
use Test::More;

use Imager::Screenshot 'screenshot';

Imager::Screenshot->have_x11
  or plan skip_all => "No X11 support";

my $display = Imager::Screenshot::x11_open()
  or plan skip_all => "Cannot connect to display: ".Imager->errstr;

Imager::Screenshot::x11_close($display);

eval "use Tk;";
$@
  and plan skip_all => "Tk not available";

my $mw = Tk::MainWindow->new;

$mw->can('windowingsystem')
  or plan skip_all => 'Cannot determine windowing system';
$mw->windowingsystem eq 'x11'
  or plan skip_all => 'Tk windowing system not X11';

plan tests => 1;

my $im;
$mw->Label(-text => "test: $0")->pack;
$mw->after(100 =>
           sub {
             $im = screenshot(widget => $mw, decor => 1)
               or print "# ", Imager->errstr, "\n";
             $mw->destroy;
           });
MainLoop();
ok($im, "grab from a Tk widget (X11)");
