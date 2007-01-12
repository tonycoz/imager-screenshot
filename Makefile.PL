#!perl -w
use strict;
use ExtUtils::MakeMaker;
use Imager::ExtUtils;
use Config;
use File::Spec;

my @objs = qw/Screenshot.o/;
my @cflags;
my @lflags;
my %seen_incdir;
my %seen_libdir;
my $X11_lib = $^O eq 'cygwin' ? 'X11.dll' : 'X11';
if (find_header("X11/Xlib.h") and find_lib($X11_lib)) {
  push @objs, 'scx11.o';
  push @cflags, '-DSS_X11';
  push @lflags, '-l'.$X11_lib;
  print "Found X11\n";
}
if (find_header('windows.h') and find_lib('gdi32')) {
  push @objs, 'scwin32.o';
  push @cflags, '-DSS_WIN32';
  if ($^O eq 'cygwin') {
    push @lflags, '-L/usr/lib/w32api', '-lgdi32';
  }
  print "Found Win32\n";
}

unless (@objs > 1) {
  die "Sorry, I can't find headers or libraries for a supported GUI\n"
}

my %opts = 
  (
   NAME => 'Imager::Screenshot',
   VERSION_FROM => 'Screenshot.pm',
   OBJECT => "@objs",
   PREREQ_PM => {
		 'Imager'    => 0.54,
		},
   INC => Imager::ExtUtils->includes,
   TYPEMAPS => [ Imager::ExtUtils->typemap ],
  );

$opts{LIBS} = "@lflags" if @lflags;
$opts{INC} .= " @cflags" if @cflags;

if ($ExtUtils::MakeMaker::VERSION > 6.06) {
  $opts{AUTHOR} = 'Tony Cook <tonyc@cpan.org>';
  $opts{ABSTRACT} = 'Screen/Window capture to Imager images';
}

if ($ExtUtils::MakeMaker::VERSION > 6.30) {
  $opts{LICENSE} = 'perl';
}

WriteMakefile(%opts);

my @incs;
sub header_search_path {
  @incs and return @incs;

  push @incs, '/usr/include', '/usr/X11R6/include'
    unless $^O eq 'MSWin32' && $Config{cc} =~ /\bcl\b/;
  push @incs, split /\Q$Config{path_sep}/, $ENV{INCLUDE}
    if $^O eq 'MSWin32' && $Config{cc} =~ /\bcl\b/ and $ENV{INCLUDE};
  push @incs, split ' ', $Config{locincpth}
    if $Config{locincpth};
  push @incs, split /\Q$Config{path_sep}/, $Config{incpath}
    if $Config{incpath};
  push @incs, '/usr/include/w32api', '/usr/X11R6/include'
    if $^O eq 'cygwin';

  @incs = grep -d, @incs;

  @incs;
}

my @libs;
sub library_search_path {
  @libs and return @libs;

  push @libs, '/usr/lib', '/usr/X11R6/lib'
    unless $^O eq 'MSWin32' && $Config{cc} =~ /\bcl\b/;
  push @libs, split /\Q$Config{path_sep}/, $ENV{LIB}
    if $^O eq 'MSWin32' && $Config{cc} =~ /\bcl\b/ and $ENV{LIB};
  push @libs, split ' ', $Config{loclibpth}
    if $Config{loclibpth};
  push @libs, split /\Q$Config{path_sep}/, $Config{libpth}
    if $Config{libpth};
  push @libs, '/usr/lib/w32api', '/usr/X11R6/lib'
    if $^O eq 'cygwin';

  @libs = grep -d, @libs;

  @libs;
}


sub _find_file {
  my ($name, @where) = @_;

  grep -f File::Spec->catfile($_, $name), @where;
}

sub find_header {
  my @found = _find_file($_[0], header_search_path());

  if (@found) {
      push @cflags, "-I$_" for grep !$seen_incdir{$_}, @found;
      @seen_incdir{@found} = (1) x @found;
  }

  @found;
}

sub find_lib {
  my $name = shift;
  my @found;
  if ($^O eq 'MSWin32' && $Config{_a} eq '.lib') {
    @found = _find_file($name . $Config{_a}, library_search_path());
  }
  else {
    @found = _find_file("lib" . $name . $Config{_a}, library_search_path());
  }
  if (@found) {
    push @lflags, "-L$_" for grep !$seen_libdir{$_}, @found;
    @seen_libdir{@found} = (1) x @found;
  }
  @found;
}
