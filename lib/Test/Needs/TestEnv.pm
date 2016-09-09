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
