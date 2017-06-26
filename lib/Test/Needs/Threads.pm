package Test::Needs::Threads;
use strict;
use warnings;
no warnings 'once';
our $VERSION = '0.002004';
$VERSION =~ tr/_//d;

use Test::Needs ();
our @ISA = qw(Test::Needs);

my $_perl;
sub _perl {
  return $_perl
    if defined $_perl;
  require File::Spec;
  require Config;
  ($_perl) = $^X =~ /(.*)/;
  (undef, my $dir, my $exe) = File::Spec->splitpath($_perl);
  $dir = undef, $_perl = 'perl'
    if $exe !~ /perl/;
  if (File::Spec->file_name_is_absolute($_perl)) {
  }
  elsif (-x $Config::Config{perlpath}) {
    $_perl = $Config::Config{perlpath};
  }
  elsif ($dir && -x $_perl) {
    $_perl = File::Spec->rel2abs($_perl);
  }
  else {
    ($_perl) =
      map /(.*)/,
      grep !-d && -x,
      map +($_, $^O eq 'MSWin32' ? ("$_.exe") : ()),
      map File::Spec->catfile($_, $_perl),
      File::Spec->path;
  }
  return $_perl;
}

my %checks;
sub _run_check {
  my $check = shift;
  return $checks{$check}
    if exists $checks{$check};

  require Config;

  my %skip = map +($_ => 1), (
    @Config::Config{qw(privlibexp archlibexp sitearchexp sitelibexp)}
  );
  my @perl = (_perl, '-T', map "-I$_", grep !$skip{$_}, @INC);

  $checks{$check} = !system @perl, '-mTest::Needs::Threads', '-eTest::Needs::Threads::_check_'.$check;
}

sub _find_missing {
  my $class = shift;
  require Config;
  if (! $Config::Config{useithreads}) {
    return "your perl does not support ithreads";
  }
  elsif (!_run_check('install')) {
    return "threads.pm not installed";
  }
  elsif (!_run_check('create')) {
    return "threads are broken on this machine";
  }
  undef;
}

sub check {
  local $Test::Builder::Level = ($Test::Builder::Level||0) + 1;
  __PACKAGE__->_needs(@_);
}

sub _needs_name { "Threads" }

sub _check_install {
  require POSIX;
  eval { require threads } or POSIX::_exit(1);
}

sub _check_create {
  require POSIX;
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

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Test::Needs::Threads - Skip tests unless threads are available

=head1 SYNOPSIS

  use Test::Needs::Threads;

  # check later
  use Test::Needs::Threads ();
  Test::Needs::Threads::check;

  # skips remainder of subtest
  use Test::More;
  use Test::Needs::Threads ();
  subtest 'my subtest' => sub {
    Test::Needs::Threads::check;
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
