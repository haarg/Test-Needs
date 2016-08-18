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
