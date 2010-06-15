#!perl -w
use strict;
use ExtUtils::MakeMaker;
use Imager 0.54;
use Imager::ExtUtils;
use Config;
use File::Spec;
use Getopt::Long;
use lib "inc";
use Devel::CheckLib;

my @incpaths; # places to look for headers
my @libpaths; # places to look for libraries

GetOptions("incpath=s", \@incpaths,
           "libpath=s" => \@libpaths);

my @objs = qw/Screenshot.o/;
my @cflags;
my @lflags;
my %seen_incdir;
my %seen_libdir;
my $X11_lib = $^O eq 'cygwin' ? 'X11.dll' : 'X11';
if (find_header("X11/Xlib.h", "X11 header") 
    and find_lib($X11_lib, "X11 library")) {
  push @objs, 'scx11.o';
  push @cflags, '-DSS_X11';
  push @lflags, '-l'.$X11_lib;
  print "Found X11\n";
}
if (find_header('windows.h', "Win32 header")
    && find_lib('gdi32', "Win32 library")
    || check_lib(header => "windows.h",
		 lib => "gdi32",
		 title => "Win32")) {
  push @objs, 'scwin32.o';
  push @cflags, '-DSS_WIN32';
  if ($^O eq 'cygwin') {
    push @lflags, '-L/usr/lib/w32api', '-lgdi32';
  }
  print "Found Win32\n";
}

unless (@objs > 1) {
  die <<DEAD;
OS unsupported: Headers or libraries not found for a supported GUI

Sorry, I can't find headers or libraries for a supported GUI
You need to install development headers and libraries for your GUI
For Win32: Platform SDK or a substitute
For X11: X11 headers and libraries, eg. the libX11-dev package on Debian

DEAD
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

# avoid "... isn't numberic in numeric gt ..." warnings for dev versions
my $eu_mm_version = eval $ExtUtils::MakeMaker::VERSION;
if ($eu_mm_version > 6.06) {
  $opts{AUTHOR} = 'Tony Cook <tonyc@cpan.org>';
  $opts{ABSTRACT} = 'Screen/Window capture to Imager images';
}

# LICENSE was introduced in 6.30_01, but Debian etch includes
# (as of 2007/01/12) an ExtUtils::MakeMaker versioned 6.30_01 without
# LICENSE support
# EXTRA_META was also introduced in 6.30_01
if ($eu_mm_version > 6.3001) {
  $opts{LICENSE} = 'perl';
}
if ($eu_mm_version >= 6.46) {
  $opts{META_MERGE} =
    {
     configure_requires => 
     {
      Imager => "0.54"
     },
     build_requires => 
     {
      Imager => "0.54",
      "Test::More" => "0.47",
     }
    };
}

WriteMakefile(%opts);

my @incs;
sub header_search_path {
  @incs and return @incs;

  push @incs, map {; split /\Q$Config{path_sep}/ } @incpaths;
  push @incs, split /\Q$Config{path_sep}/, $ENV{IM_INCPATH}
    if defined $ENV{IM_INCPATH};
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

  push @libs, map {; split /\Q$Config{path_sep}/ } @libpaths;
  push @incs, split /\Q$Config{path_sep}/, $ENV{IM_LIBPATH}
    if defined $ENV{IM_LIBPATH};
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
  my ($name, $description) = @_;
  my @found = _find_file($_[0], header_search_path());

  if (@found) {
    push @cflags, "-I$_" for grep !$seen_incdir{$_}, @found;
    @seen_incdir{@found} = (1) x @found;
  }
  else {
    print STDERR "Could not find $name ($description)\n";
  }

  @found;
}

sub find_lib {
  my ($name, $description) = shift;
  my @found;
  my $libname;
  if ($^O eq 'MSWin32' && $Config{_a} eq '.lib') {
    $libname = $name . $Config{_a};
    @found = _find_file($libname, library_search_path());
  }
  else {
    $libname = "lib" . $name . $Config{_a};
    @found = _find_file($libname, library_search_path());
    if (!@found && $Config{so}) {
      $libname = "lib" . $name . "." . $Config{so};
      @found = _find_file($libname, library_search_path());
    }
  }
  if (@found) {
    push @lflags, "-L$_" for grep !$seen_libdir{$_}, @found;
    @seen_libdir{@found} = (1) x @found;
  }
  else {
    print STDERR "Could not find $libname ($description)\n";
  }

  @found;
}

# wrapper around assert lib that doesn't exit and doesn't die
sub check_lib {
  my (%opts) = @_;

  my $title = delete $opts{title};
  $title and print "Looking even harder for $title\n";

  return eval { assert_lib(%opts); 1 };
}
