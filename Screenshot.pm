package Imager::Screenshot;
use strict;
use vars qw(@ISA $VERSION @EXPORT_OK);
use Imager;
require Exporter;

push @ISA, 'Exporter';
@EXPORT_OK = 'screenshot';

BEGIN {
  require Exporter;
  @ISA = qw(Exporter);
  $VERSION = '0.003';
  eval {
    # try XSLoader first, DynaLoader has annoying baggage
    require XSLoader;
    XSLoader::load('Imager::Screenshot' => $VERSION);
    1;
  } or do {
    require DynaLoader;
    push @ISA, 'DynaLoader';
    bootstrap Imager::Screenshot $VERSION;
  }
}

sub screenshot {
  # lose the class if called as a method
  @_ % 2 == 1 and shift;

  my %opts = 
    (
     decor => 0, 
     display => 0, 
     left => 0, 
     top => 0,
     right => 0,
     bottom => 0,
     @_);

  my $result;
  if (defined $opts{hwnd}) {
    defined &_win32
      or die "Win32 driver not enabled\n";
    $result = _win32($opts{hwnd}, $opts{decor}, $opts{left}, $opts{top},
		     $opts{right}, $opts{bottom});
  }
  elsif (defined $opts{id}) { # X11 window id
    defined &_x11
      or die "X11 driver not enabled\n";
    $result = _x11($opts{display}, $opts{id}, $opts{left}, $opts{top},
		   $opts{right}, $opts{bottom});
  }
  elsif ($opts{widget}) {
    # Perl/Tk widget
    my $top = $opts{widget}->toplevel;
    my $sys = $top->windowingsystem;
    if ($sys eq 'win32') {
      unless (defined &_win32) {
        Imager->_set_error("Win32 Tk and Win32 support not built");
        return;
      }
      $result = _win32(hex($opts{widget}->id), $opts{decor}, 
		       $opts{left}, $opts{top}, $opts{right}, $opts{bottom});
    }
    elsif ($sys eq 'x11') {
      unless (defined &_x11) {
        Imager->_set_error("X11 Tk and X11 support not built");
        return;
      }

      my $id_hex = $opts{widget}->id;
      $opts{widget}->can('frame') 
        and $id_hex = $opts{widget}->frame;
      
      # is there a way to get the display pointer from Tk?
      $result = _x11($opts{display}, hex($id_hex), $opts{left}, $opts{top},
		     $opts{right}, $opts{bottom});
    }
    else {
      Imager->_set_error("Unsupported windowing system '$sys'");
      return;
    }
  }
  else {
    $result =
      defined &_win32 ? _win32(0, $opts{decor}, $opts{left}, $opts{top},
			       $opts{right}, $opts{bottom}) :
	defined &_x11 ? _x11($opts{display}, 0, $opts{left}, $opts{top},
			     $opts{right}, $opts{bottom}) :
	   die "No drivers enabled\n";
  }

  unless ($result) {
    Imager->_set_error(Imager->_error_as_msg());
    return;
  }
  
  return $result;
}

sub have_win32 {
  defined &_win32;
}

sub have_x11 {
  defined &_x11;
}

sub x11_open {
  my $display = _x11_open(@_);
  unless ($display) {
    Imager->_set_error(Imager->_error_as_msg);
    return;
  }

  return $display;
}

sub x11_close {
  _x11_close(shift);
}

1;

__END__

=head1 NAME

Imager::Screenshot - screenshot to an Imager image

=head1 SYNOPSIS

  use Imager::Screenshot 'screenshot';

  # whole screen
  my $img = screenshot();

  # Win32 window
  my $img2 = screenshot(hwnd => $hwnd);

  # X11 window
  my $img3 = screenshot(display => $display, id => $window_id);

  # X11 tools
  my $display = Imager::Screenshot::x11_open();
  Imager::Screenshot::x11_close($display);

  # test for win32 support
  if (Imager::Screenshot->have_win32) { ... }

  # test for x11 support
  if (Imager::Screenshot->have_x11) { ... }
  

=head1 DESCRIPTION

Imager::Screenshot captures either a desktop or a specified window and
returns the result as an Imager image.

Currently the image is always returned as a 24-bit image.

=over

=item screenshot hwnd => I<window handle>

=item screenshot hwnd => I<window handle>, decor => <capture decorations>

Retrieve a screenshot under Win32, if I<window handle> is zero,
capture the desktop.

By default, window decorations are not captured, if the C<decor>
parameter is set to true then window decorations are included.

=item screenshot id => I<window id>

=item screenshot id => I<window id>, display => I<display object>

Retrieve a screenshot under X11, if I<id> is zero, capture the root
window.  I<display object> is a integer version of an X11 C< Display *
>, if this isn't supplied C<screenshot()> will attempt connect to the
the display specified by $ENV{DISPLAY}.

Note: taking a screenshot of a remote display is slow.

=item screenshot

If no C<id> or C<hwnd> parameter is supplied:

=over

=item *

if Win32 support is compiled, return screenshot(hwnd => 0).

=item *

if X11 support is compiled, return screenshot(id => 0).

=item *

otherwise, die.

=back

You can also supply the following parameters to retrieve a subset of
the window:

=over

=item *

left

=item *

top

=item *

right

=item *

bottom

=back

If left or top is negative, then treat that as from the right/bottom
edge of the window.

If right ot bottom is zero or negative then treat as from the
right/bottom edge of the window.

So setting all 4 values to 0 retrieves the whole window.

  # a 10-pixel wide right edge of the window
  my $right_10 = screenshot(left => -10, ...);

  # the top-left 100x100 portion of the window
  my $topleft_100 = screenshot(right => 100, bottom => 100, ...);

  # 10x10 pixel at the bottom right corner
  my $bott_right_10 = screenshot(left => -10, top => -10, ...);

=item have_win32

Returns true if Win32 support is available.

=item have_x11

Returns true if X11 support is available.

=item Imager::Screenshot::x11_open

=item Imager::Screenshot::x11_open I<display name>

Attempts to open a connection to either the display name in
$ENV{DISPLAY} or the supplied display name.  Returns a value suitable
for the I<display> parameter of screenshot, or undef.

=item Imager::Screenshot::x11_close I<display>

Closes a display returned by Imager::Screenshot::x11_open().

=back

=head1 CAVEATS

It's possible to have more than one grab driver available, for
example, Win32 and X11, and which is used can have an effect on the
result.

Under Win32, if there's a screesaver running, then you grab the
results of the screensaver.

Grabbing the root window on a rootless server (eg. Cygwin/X) may not
grab the background.  In fact, when I tested under Cygwin/X I got the
xterm window contents even when the Windows screensaver was running.

=head1 LICENSE

Imager::Screenshot is licensed under the same terms as Perl itself.

=head1 AUTHOR

Tony Cook <tonyc@cpan.org>

=cut


