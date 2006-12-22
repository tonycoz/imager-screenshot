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
  $VERSION = '0.001';
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

  my %opts = (decor => 1, @_);

  my $result;
  if (!@_) {
    my $result =
      defined &win32 ? win32(0) :
	defined &x11 ? x11(0) :
	   die "No drivers enabled\n";
  }
  if (defined $opts{hwnd}) {
    defined &win32
      or die "Win32 driver not enabled\n";
    $result = win32($opts{hwnd}, $opts{decor});
  }
  elsif (defined $opts{id}) { # X11 window id
    defined &x11
      or die "X11 driver not enabled\n";
    $result = x11($opts{id});
  }

  unless ($result) {
    Imager->_set_error(Imager->_error_as_msg());
    return;
  }
  
  return $result;
}

sub have_win32 {
  defined &win32;
}

sub have_x11 {
  defined &x11;
}

# everything else is XS
1;

__END__

=head1 NAME

Imager::Screenshot - screenshot to an Imager image

=head1 SYNOPSIS

  use Imager::Screenshot 'screeshot';

  # whole screen
  my $img = screenshot();

=head1 DESCRIPTION


=head1 AUTHOR

Tony Cook <tonyc@cpan.org>

=cut


