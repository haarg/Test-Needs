package Test::Needs::TestEnv;
use strict;
use warnings;
no warnings 'once';
our $VERSION = '0.002004';
$VERSION =~ tr/_//d;

use Test::Needs ();
our @ISA = qw(Test::Needs);

our @EXPORT = qw(testenv);

my %types = (
  smoke           => 'AUTOMATED_TESTING',
  automated       => 'AUTOMATED_TESTING',
  interactive     => 'NONINTERACTIVE_TESTING',
  extended        => 'EXTENDED_TESTING',
  author          => 'AUTHOR_TESTING',
  release         => 'RELEASE_TESTING',
);

sub _find_missing {
  my $class = shift;
  my @bad =
    map {
      my $type = $_;
      $type =~ s/^-//;
      my $env = $types{$type}
          or Test::Needs::_croak "Invalid test type $type",
      my $val = $ENV{$env};
      $type eq 'interactive' ? do {
        my $reason
          = $val                      ? "$env set"
          : $ENV{AUTOMATED_TESTING}   ? "AUTOMATED_TESTING set"
          : $ENV{PERL_MM_USE_DEFAULT} ? "PERL_MM_USE_DEFAULT set"
          : (not -t STDIN && ( -t STDOUT || !( -f STDOUT || -c STDOUT ) ) ) ? "no terminal"
          : undef;
        $reason ? "$reason preventing $type testing" : ();
      }
      : !$val ? "$env not set for $type testing"
      : ()
    }
    @_;
  @bad ? join(', ', @bad) : undef;
}

sub testenv {
  local $Test::Builder::Level = ($Test::Builder::Level||0) + 1;
  __PACKAGE__->_needs(@_);
}

sub _needs_name { "Test Environment" }

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Test::Needs::TestEnv - Skip tests unless in given test environment

=head1 SYNOPSIS

  use Test::Needs::TestEnv qw(
    smoke
    automated
    interactive
    extended
    author
    release
  );

  use Test::Needs::TestEnv -smoke;

  # check later
  use Test::Needs::TestEnv;
  testenv 'automated';

  # skips remainder of subtest
  use Test::More;
  use Test::Needs::TestEnv;
  subtest 'my subtest' => sub {
    testenv 'automated';
    ...
  };

=head1 DESCRIPTION

Skip test scripts if not being run under the listed environments.

=head1 EXPORTS

=head2 testenv

Has the same interface as when using Test::Needs::Internet in a C<use>.

=head1 ENVIRONMENTS

=head2 smoke

The C<AUTOMATED_TESTING> environment variable must be set.

=head2 automated

The C<AUTOMATED_TESTING> environment variable must be set.

=head2 interactive

None of the C<NONINTERACTIVE_TESTING>, L<AUTOMATED_TESTING>, or
L<PERL_MM_USE_DEFAULT> environment variables must be set, and STDIN and STDOUT
must be connected to a terminal.

=head2 extended

The C<EXTENDED_TESTING> environment variable must be set.

=head2 author

The C<AUTHOR_TESTING> environment variable must be set.

=head2 release

The C<RELEASE_TESTING> environment variable must be set.

=head1 SEE ALSO

=over 4

=item L<Test::Settings>

Allows inspecting and setting the related environment variables, with no skip
functions.

=item L<Test::DescribeMe>

Will only perform a C<skip_all>.  C<interactive> only checks
C<NONINTERACTIVE_TESTING>.  Does not include C<automated> alias.

=item L<Test::Is>

Will only perform a C<skip_all>.  Only supports C<interactive> and C<extended>.
C<interactive> only checks C<NONINTERACTIVE_TESTING>.
Includes perl version checking.

=item L<Test2::Require::AuthorTesting>

Will only perform a C<skip_all>.  Only checks C<AUTHOR_TESTING>.  Requires
L<Test2>.

=back

=head1 AUTHORS

See L<Test::Needs|Test::Needs/AUTHORS> for authors.

=head1 COPYRIGHT AND LICENSE

See L<Test::Needs|Test::Needs/COPYRIGHT AND LICENSE> for the copyright and
license.

=cut
