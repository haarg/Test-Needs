package TestScript;
use strict;
use warnings;

our $die;
END {
  if ($die) {
    $? = $? ? 0 : 1;
    warn "setting exit to $?";
  }
}

sub import {
  my $class = shift;
  my $opts = { map { /^--([^=]*)(?:=(.*))?/ ? ($1 => $2||1) : () } @_ };
  my @args = grep !/^--/, @_;
  @args = @args == 1 ? @args : { @args };
  $die = $opts->{die};
  if ($opts->{load}) {
    eval qq{ package main; use $opts->{load}; 1; } or die $@;
  }

  if ($opts->{subtest}) {
    require Test::More;
    Test::More::plan(tests => 1);
    Test::More::subtest('subtest' => sub { do_test($opts, @args) });
  }
  else {
    do_test($opts, @args);
  }
  exit 0;
}


sub do_test {
  my ($opts, @args) = @_;
  require Test::Needs;
  if ($opts->{plan}) {
    require Test::More;
    Test::More::plan(tests => 2);
  }
  elsif ($opts->{no_plan}) {
    require Test::More;
    Test::More::plan('no_plan');
  }
  if ($opts->{tests}) {
    require Test::More;
    Test::More::pass();
  }
  Test::Needs::needs(@args);
  require Test::More;
  Test::More::plan(tests => 2)
    unless $opts->{tests} || $opts->{plan} || $opts->{no_plan};
  Test::More::pass();
  Test::More::pass()
    unless $opts->{tests};
  Test::More::done_testing()
    if $opts->{tests} && !($opts->{plan} || $opts->{no_plan});
}

1;
