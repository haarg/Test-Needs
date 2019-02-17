package Test::Needs::Env;
use strict;
use warnings;
no warnings 'once';
our $VERSION = '0.002004';
$VERSION =~ tr/_//d;

use Test::Needs ();
our @ISA = qw(Test::Needs);

our @EXPORT = qw(test_needs_env);

sub _to_pairs;
*_to_pairs = \&Test::Needs::_to_pairs;

sub _find_missing {
  my $class = shift;
  my @bad =
    map {
      my ($env, $check) = @$_;
      @_ == 2 && !defined $check ? (
        exists $ENV{$env} ? "$env is set" : ()
      )
      : !exists $ENV{$env} ? "$env not set"
      : !defined $check ? "$env is set"
      : !ref $check ? (
        $ENV{$env} ne $check ? "$env not set to $check" : ()
      )
      : eval { $check = \&$check; 1 } ? (
        eval { $check->($ENV{$env}) } ? () : do {
          my $e = $@ || "$env failed check";
          $e =~ s/\n\z//;
          $e;
        }
      )
      : $ENV{$env} !~ $check ? "$env doesn't match $check"
      : ();
    } _to_pairs(@_);
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
