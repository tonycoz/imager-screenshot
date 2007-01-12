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

  my %opts = (decor => 0, display => 0, @_);

  my $result;
  if (!@_) {
    my $result =
      defined &_win32 ? _win32(0) :
	defined &_x11 ? _x11($opts{display}, 0) :
	   die "No drivers enabled\n";
  }
  if (defined $opts{hwnd}) {
    defined &_win32
      or die "Win32 driver not enabled\n";
    $result = _win32($opts{hwnd}, $opts{decor});
  }
  elsif (defined $opts{id}) { # X11 window id
    defined &_x11
      or die "X11 driver not enabled\n";
    $result = _x11($opts{display}, $opts{id});
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
      $result = _win32(hex($opts{widget}->id));
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
      $result = _x11(0, hex($id_hex));
    }
    else {
      Imager->_set_error("Unsupported windowing system '$sys'");
      return;
    }
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

If no parameters are supplied:

=over

=item *

if Win32 support is compiled, return screenshot(hwnd => 0).

=item *

if X11 support is compiled, return screenshot(id => 0).

=item *

otherwise, die.

=back

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

=head1 LICENSE

Imager::Screenshot is licensed under the same terms as Perl itself.

=head1 AUTHOR

Tony Cook <tonyc@cpan.org>

=cut


