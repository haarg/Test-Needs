use strict;
use warnings;
use Test::More;
use Test::Needs ();

my @try = (
  [ '5'           => '5.000000' ],
  [ 'v5'          => '5.000000' ],
  [ '"5"'         => '5.000000' ],
  [ '"v5"'        => '5.000000' ],

  [ '5.008000'    => '5.008000' ],
  [ '5.8.0'       => '5.008000' ],
  [ 'v5.8.0'      => '5.008000' ],
  [ '"5.8.0"'     => '5.008000' ],
  [ '"v5.8.0"'    => '5.008000' ],

  [ 'v5.999.0'    => '5.999000' ],
  [ '5.999000'    => '5.999000' ],
  [ '5.999.0'     => '5.999000' ],
  [ '"5.999.0"'   => '5.999000' ],
  [ '"v5.999.0"'  => '5.999000' ],
);

plan tests => 1 + scalar @try;

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_; warn @_ };

for (@try) {
  my ($in, $want) = @$_;
  my $evaled = eval $in;
  die $@ if $@;
  my $got = Test::Needs::_numify_version($evaled);
  is $got, $want, sprintf "%10s parses correctly as %s", $in, $want;
}

is scalar @warnings, 0, "no warnings";
