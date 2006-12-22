use strict;
use ExtUtils::MakeMaker;
use Imager::ExtUtils;
use Config;
use File::Spec;

my @objs = qw/Screenshot.o/;
my @cflags;
my @lflags;
#if (find_header("X11.h") and find_lib("X11")) {
#  push @objs, 'scx11.o';
#  push @cflags, '-DSS_X11';
#  push @lflags, '-lX11';
#  print "Found X11\n";
#}
if (find_header('windows.h') and find_lib('gdi32')) {
  push @objs, 'scwin32.o';
  push @cflags, '-DSS_WIN32';
  push @lflags, '-lgdi32' if $^O eq 'cygwin';
  print "Found Win32\n";
}

unless (@objs) {
  WriteEmptyMakefile();
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

WriteMakefile(%opts);

my @incs;
sub header_search_path {
  @incs and return @incs;

  push @incs, split /\Q$Config{path_sep}/, $ENV{INCLUDE}
    if $^O eq 'MSWin32' && $Config{cc} =~ /\bcl\b/ and $ENV{INCLUDE};
  push @incs, split ' ', $Config{locincpth}
    if $Config{locincpth};
  push @incs, split /\Q$Config{path_sep}/, $Config{incpath}
    if $Config{incpath};

  @incs = grep -d, @incs;

  @incs;
}

my @libs;
sub library_search_path {
  @libs and return @libs;

  push @libs, split /\Q$Config{path_sep}/, $ENV{LIB}
    if $^O eq 'MSWin32' && $Config{cc} =~ /\bcl\b/ and $ENV{LIB};
  push @libs, split ' ', $Config{loclibpth}
    if $Config{loclibpth};
  push @libs, split /\Q$Config{path_sep}/, $Config{libpth}
    if $Config{libpth};

  @libs = grep -d, @libs;

  @libs;
}


sub _find_file {
  my ($name, @where) = @_;

  grep -f File::Spec->catfile($_, $name), @where;
}

sub find_header {
  _find_file($_[0], header_search_path());
}

sub find_lib {
  my $name = shift;
  if ($^O eq 'MSWin32') {
    return _find_file($name . $Config{_a}, library_search_path());
  }
  else {
    return _find_file("lib" . $name . $Config{_a}, library_search_path());
  }
}
