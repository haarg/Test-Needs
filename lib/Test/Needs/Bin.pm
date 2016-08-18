package Test::Needs::Bin;
use strict;
use warnings;
no warnings 'once';
our $VERSION = '0.002004';
$VERSION =~ tr/_//d;

use Test::Needs ();
our @ISA = qw(Test::Needs);

use File::Which ();

our @EXPORT = qw(test_needs_bin);

sub _find_missing {
  my $class = shift;
  my @bad = grep !File::Which::which($_), @_;
  @bad ? "Need " . join(', ', @bad) : undef;
}

sub test_needs_bin {
  local $Test::Builder::Level = ($Test::Builder::Level||0) + 1;
  __PACKAGE__->_needs(@_);
}

sub _needs_name { "Programs" }

1;
