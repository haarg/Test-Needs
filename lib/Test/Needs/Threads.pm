package Test::Needs::Threads;
use strict;
use warnings;
no warnings 'once';
our $VERSION = '0.002004';
$VERSION =~ tr/_//d;

BEGIN {
  if (!caller && @ARGV) {
    my ($op) = @ARGV;
    require POSIX;
    if ($op eq '--install-check') {
      eval { require threads } or POSIX::_exit(1);
    }
    elsif ($op eq '--create-check') {
      require threads;
      require File::Spec;
      open my $olderr, '>&', \*STDERR
        or die "can't dup filehandle: $!";
      open STDERR, '>', File::Spec->devnull
        or die "can't open null: $!";
      my $out = threads->create(sub { 1 })->join;
      open STDERR, '>&', $olderr;
      POSIX::_exit((defined $out && $out eq '1') ? 0 : 1);
    }
    else {
      die "Invalid option $op!\n";
    }
    POSIX::_exit(0);
  }
}

use Config;
use File::Spec;
use Test::Needs ();
our @ISA = qw(Test::Needs);

my $FILE = File::Spec->rel2abs(__FILE__);

my $_PERL;
{
  ($_PERL) = $^X =~ /(.*)/;
  (undef, my $dir, my $exe) = File::Spec->splitpath($_PERL);
  $dir = undef, $_PERL = 'perl'
    if $exe !~ /perl/;
  if (File::Spec->file_name_is_absolute($_PERL)) {
  }
  elsif (-x $Config{perlpath}) {
    $_PERL = $Config{perlpath};
  }
  elsif ($dir && -x $_PERL) {
    $_PERL = File::Spec->rel2abs($_PERL);
  }
  else {
    ($_PERL) =
      map /(.*)/,
      grep !-d && -x,
      map +($_, $^O eq 'MSWin32' ? ("$_.exe") : ()),
      map File::Spec->catfile($_, $_PERL),
      File::Spec->path;
  }
}

sub _tainted {
  local ($@, $SIG{__DIE__});
  return ! eval { eval("#" . substr(join("", @_), 0, 0)); 1 };
}

sub _find_missing {
  my $class = shift;
  if (! $Config{useithreads}) {
    return "your perl does not support ithreads";
  }

  my $archname = $Config{archname};
  my $version = $Config{version};
  my @inc_version_list = grep length $_, reverse split / /, $Config{inc_version_list};
  my $path_sep = $Config{path_sep};

  my %skip = map +($_ => 1),
    @Config{qw(privlibexp archlibexp sitearchexp sitelibexp)},
    (
      map +(
        $_,
        grep -d,
        map File::Spec->catdir(@$_),
        [$_, $version, $archname],
        [$_, $version],
        [$_, $archname],
        (@inc_version_list ? do {
          my $d = $_;
          map [$d, $_], @inc_version_list;
        } : ()),
      ),
      map +(split /\Q$path_sep/),
      grep !_tainted($_),
      (
        exists $ENV{PERL5LIB} ? $ENV{PERL5LIB}
        : exists $ENV{PERLLIB} ? $ENV{PERLLIB}
        : ()
      )
    );

  my @taintenv = grep _tainted($ENV{$_}), qw(PATH);

  local @ENV{@taintenv};
  delete @ENV{@taintenv};

  my @perl = ($_PERL, '-T', map "-I$_", grep !$skip{$_}, @INC);

  if (system @perl, $FILE, '--install-check') {
    return "threads.pm not installed";
  }
  elsif (system @perl, $FILE, '--create-check') {
    return "threads are broken on this machine";
  }
  undef;
}

sub check {
  local $Test::Builder::Level = ($Test::Builder::Level||0) + 1;
  __PACKAGE__->_needs(@_);
}

sub _needs_name { "Threads" }

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Test::Needs::Threads - Skip tests unless threads are available

=head1 SYNOPSIS

  use Test::Needs::Threads;

  # check later
  use Test::Needs::TestEnv ();
  Test::Needs::TestEnv::check;

  # skips remainder of subtest
  use Test::More;
  use Test::Needs::Threads ();
  subtest 'my subtest' => sub {
    Test::Needs::TestEnv::check;
    ...
  };

=head1 DESCRIPTION

Skip test scripts if threads are not available and working.

=head1 SUBROUTINES

=head2 check

Checks for threads support just like a C<use>.

=head1 SEE ALSO

=over 4

=item L<Test2::Require::Threads>

Part of the L<Test2> ecosystem.  Only supports running as a C<use> command to
skip an entire plan.  Does not check thread creation.

=back

=head1 AUTHORS

See L<Test::Needs|Test::Needs/AUTHORS> for authors.

=head1 COPYRIGHT AND LICENSE

See L<Test::Needs|Test::Needs/COPYRIGHT AND LICENSE> for the copyright and
license.

=cut
