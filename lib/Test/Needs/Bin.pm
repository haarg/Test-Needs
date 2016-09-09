package Test::Needs::Bin;
use strict;
use warnings;
no warnings 'once';
our $VERSION = '0.002004';
$VERSION =~ tr/_//d;

use Test::Needs ();
our @ISA = qw(Test::Needs);

use File::Spec;
use ExtUtils::MakeMaker ();

our @EXPORT = qw(test_needs_bin);

sub _find_missing {
  my $class = shift;
  my @bad = grep {
    my $cmd = $_;
    !(
      grep !-d $_ && -x _ || MM->maybe_command($_),
      (
        File::Spec->file_name_is_absolute($cmd)
        || File::Spec->splitdir($cmd) > 1
      ) ? $cmd
      : map File::Spec->catfile($_, $cmd),
        File::Spec->path
    )
  } @_;
  @bad ? "Need " . join(', ', @bad) : undef;
}

sub test_needs_bin {
  local $Test::Builder::Level = ($Test::Builder::Level||0) + 1;
  __PACKAGE__->_needs(@_);
}

sub _needs_name { "Programs" }

1;
