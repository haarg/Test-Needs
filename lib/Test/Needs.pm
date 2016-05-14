package Test::Needs;
use strict;
use warnings;
our $VERSION = '0.001003';
$VERSION =~ tr/_//d;

my $TEST;

BEGIN {
  *_WORK_AROUND_HINT_LEAKAGE
    = "$]" < 5.011 && !("$]" >= 5.009004 && "$]" < 5.010001)
    ? sub(){1} : sub(){0};
}

sub _try_require {
  local %^H
    if _WORK_AROUND_HINT_LEAKAGE;
  my ($module, $version) = @_;
  (my $file = "$module.pm") =~ s{::|'}{/}g;
  my $err;
  {
    local $@;
    eval { require $file }
      or $err = $@;
  }
  if (defined $err) {
    die $err
      unless $err =~ /\ACan't locate \Q$file\E/;
    return !1;
  }
  !0;
};

sub import {
  my $class = shift;
  my @bad = map {
    my ($module, $version) = @$_;
    if (_try_require($module)) {
      local $@;
      if (defined $version && !eval { $module->VERSION($version); 1 }) {
        "$module $version (have ".$module->VERSION.')';
      }
      else {
        ();
      }
    }
    else {
      $module;
    }
  }
  map {
    if (ref) {
      my $arg = $_;
      map [ $_ => $arg->{$_} ], sort keys %$arg;
    }
    else {
      [ $_ => undef ];
    }
  } @_;

  if (@bad) {
    my $message = 'Need ' . join ', ', @bad;
    if ($TEST || $INC{'Test2/API.pm'} || $INC{'Test/Builder.pm'}) {
      $TEST ||= do { require Test::Builder; Test::Builder->new };
    }
    if ($TEST) {
      if ($ENV{RELEASE_TESTING}) {
        $TEST->ok(0, "Test::Needs modules available");
        $TEST->diag($message);
        $TEST->no_header(1);
      }
      $TEST->skip_all($message);
    }
    else {
      if ($ENV{RELEASE_TESTING}) {
        print "1..1\n";
        print "not ok 1 - Test::Needs modules available\n";
        print STDERR "#   $message\n";
        exit 1;
      }
      else {
        print "1..0 # SKIP $message\n";
        exit 0;
      }
    }
  }
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Test::Needs - Skip tests when modules not available

=head1 SYNOPSIS

  use Test::Needs 'Foo', {
    'Some::Module' => '1.005',
  };

=head1 DESCRIPTION

Skip tests if modules are not available.

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head1 CONTRIBUTORS

None so far.

=head1 COPYRIGHT

Copyright (c) 2016 the Test::Needs L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
