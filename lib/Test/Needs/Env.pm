package Test::Needs::Env;
use strict;
use warnings;
no warnings 'once';
our $VERSION = '0.002004';
$VERSION =~ tr/_//d;

use Test::Needs ();
our @ISA = qw(Test::Needs);

our @EXPORT = qw(test_needs_env);

sub _find_missing {
  my $class = shift;
  my @bad =
    map {
      my ($env, $check) = @$_;
        !exists $ENV{$env} ? "$env not set"
      : !defined $check ? ()
      : !ref $check ? (
        $ENV{$env} ne $check ? "$env not set to $check" : ()
      )
      : (
        $ENV{$env} !~ $check ? "$env doesn't match $check" : ()
      );
    }
    map {
      my $e = $_;
      !ref $e ? [$e]
      : ref $e eq 'HASH'  ? (map [ $_ => $e->{$_} ], sort keys %$e)
      : ref $e eq 'ARRAY' ? (map [ $e->[$_*2] => $e->[$_*2+1] ], 0 .. @$_ / 2 )
      : Test::Needs::_croak "Invalid environment spec ".ref $e;
    } @_;
  @bad ? join(', ', @bad) : undef;
}

sub test_needs_env {
  local $Test::Builder::Level = ($Test::Builder::Level||0) + 1;
  __PACKAGE__->_needs(@_);
}

sub _needs_name { "Environment" }

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Test::Needs::Env - Skip tests when environment variables not set

=head1 SYNOPSIS

  use Test::Needs::Env
    'HOME',                         # variable must exist
    {
      SHELL => '/bin/bash',         # specific value required
      PATH  => qr{/usr/local/bin},  # must match regex
    },
  ;

  # check later
  use Test::Needs::Env;
  test_needs_env 'SHELL';

  # skips remainder of subtest
  use Test::More;
  use Test::Needs::Env;
  subtest 'my subtest' => sub {
    test_needs_env 'SHELL';
    ...
  };

=head1 DESCRIPTION

Skip test scripts if the listed environment variables are not set.  Skipping is
done in the same manner as L<Test::Needs>.

Can also be provided a hashref of variables and values.  For regex values, the
variable must match the regex.  For strings, the variable must match the string
exactly.

=head1 EXPORTS

=head2 test_needs_env

Has the same interface as when using Test::Needs::Env in a C<use>.

=head1 SEE ALSO

=over 4

=item L<Test::Requires::Env>

Less compatible with ancient versions of Test::More, and doesn't promote skips
to failures under C<RELEASE_TESTING>.

=item L<Test2::Require::EnvVar>

Part of the L<Test2> ecosystem.  Only supports running as a C<use> command to
skip an entire plan.  Only checks for environment variables being set.

=back

=head1 AUTHORS

See L<Test::Needs|Test::Needs/AUTHORS> for authors.

=head1 COPYRIGHT AND LICENSE

See L<Test::Needs|Test::Needs/COPYRIGHT AND LICENSE> for the copyright and
license.

=cut
