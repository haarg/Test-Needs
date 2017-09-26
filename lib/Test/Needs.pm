package Test::Needs;
use strict;
use warnings;
no warnings 'once';
our $VERSION = '0.002005';
$VERSION =~ tr/_//d;

BEGIN {
  *_WORK_AROUND_HINT_LEAKAGE
    = "$]" < 5.011 && !("$]" >= 5.009004 && "$]" < 5.010001)
    ? sub(){1} : sub(){0};
  *_WORK_AROUND_BROKEN_MODULE_STATE
    = "$]" < 5.009
    ? sub(){1} : sub(){0};
}

our @EXPORT = qw(test_needs);

our @ISA = qw(Test::Needs::Base);

sub _croak;
*_croak = \&Test::Needs::Util::_croak;

sub _try_require {
  local %^H
    if _WORK_AROUND_HINT_LEAKAGE;
  my ($module) = @_;
  (my $file = "$module.pm") =~ s{::|'}{/}g;
  my $err;
  {
    local $@;
    eval { require $file }
      or $err = $@;
  }
  if (defined $err) {
    delete $INC{$file}
      if _WORK_AROUND_BROKEN_MODULE_STATE;
    die $err
      unless $err =~ /\ACan't locate \Q$file\E/;
    return !1;
  }
  !0;
}

sub _try_version {
  my ($module, $version) = @_;
  local $@;
  !!eval { $module->VERSION($version); 1 };
}

sub _numify_version {
  for ($_[0]) {
    return
        !$_ ? 0
      : /^[0-9]+\.[0-9]+$/ ? sprintf('%.6f', $_)
      : /^v?([0-9]+(?:\.[0-9]+)+)$/
        ? sprintf('%d.%03d%03d', ((split /\./, $1), 0, 0)[0..2])
      : /^(\x05)(.*)$/s
        ? sprintf('%d.%03d%03d', map ord, $1, split //, $2)
      : _croak qq{version "$_" does not look like a number};
  }
}

sub _stringify_version {
  my $version = shift;
  my @parts = $version =~ /^([0-9]+)(?:\.([0-9]{1,3})+)?/;
  $_ = int(substr($_."00",0,3))
    for @parts[1..$#parts];
  push @parts, 0
    while @parts < 3;
  join '.', @parts;
}

sub _find_missing {
  my $class = shift;
  map {
    my ($module, $version) = @$_;
    $module eq 'perl' ? do {
      $version = _numify_version($version);
      "$]" < $version ? (sprintf "perl %s (have %s)", map _stringify_version($_), $version, $]) : ()
    }
    : $module =~ /^\d|[^\w:]|:::|[^:]:[^:]|^:|:$/
      ? _croak sprintf qq{"%s" does not look like a module name}, $module
    : _try_require($module) ? (
      defined $version && !_try_version($module, $version)
        ? "$module $version (have ".(defined $module->VERSION ? $module->VERSION : 'undef').')'
        : ()
    )
    : $version ? "$module $version"
    : $module;
  }
  Test::Needs::Util::_pairs(@_);
}

sub _name { 'Modules' . ($_[1] ? '' : ' not'). ' available' }
sub _missing_format { 'Need %s' }

sub test_needs {
  local $Test::Builder::Level = ($Test::Builder::Level||0) + 1;
  __PACKAGE__->_needs(@_);
}

package
  Test::Needs::Base;

sub _name;

sub _promote_to_failure { $ENV{RELEASE_TESTING} }
sub _missing_format { '%s' }

sub import {
  my $class = shift;
  my $target = caller;
  if (@_) {
    local $Test::Builder::Level = ($Test::Builder::Level||0) + 1;
    $class->_needs(@_);
  }
  no strict 'refs';
  *{"${target}::$_"} = \&{"${class}::$_"}
    for @{"${class}::EXPORT"};
}

sub _needs {
  my $class = shift;
  my @missing = $class->_find_missing(@_) or return;
  my $message = sprintf $class->_missing_format, join(', ', @missing);
  local $Test::Builder::Level = ($Test::Builder::Level||0) + 1;
  my $fail = $class->_promote_to_failure;
  Test::Needs::Util::_finish_test($class->_name($fail), $message, $fail);
}

package
  Test::Needs::Util;

sub _pairs {
  map +(
    ref eq 'HASH' ? do {
      my $arg = $_;
      map [ $_ => $arg->{$_} ], sort keys %$arg;
    }
    : ref eq 'ARRAY' ? do {
      my $arg = $_;
      map [ @{$arg}[$_*2,$_*2+1] ], 0 .. int($#$arg / 2);
    }
    : [ $_ ]
  ), @_;
}

sub _croak {
  my $message = join '', @_;
  my $i = 1;
  while (my ($p, $f, $l) = caller($i++)) {
    next
      if $p =~ /\ATest::Needs(?:\z|::)/;
    die "$message at $f line $l.\n";
  }
  die $message;
}

sub _create_needs_sub {
  my $sub = shift;
  my $caller = caller;
  no strict 'refs';
  *{$caller.'::'.$sub} = sub {
    local $Test::Builder::Level = ($Test::Builder::Level||0) + 1;
    $caller->_needs(@_);
  };
}

sub _finish_test {
  my ($name, $message, $fail) = @_;
  my $full_message = "$name: $message";
  if ($INC{'Test2/API.pm'}) {
    my $level = -1;
    while (my $c = caller(++$level) or $level = 0) {
      last
        if $c !~ /\ATest::Needs(?:::|\z)/;
    }
    my $ctx = Test2::API::context(level => $level);
    my $hub = $ctx->hub;
    if ($fail) {
      $ctx->ok(0, $name, [$message]);
    }
    else {
      my $plan = $hub->plan;
      my $tests = $hub->count;
      if ($plan || $tests) {
        my $skips
          = $plan && $plan ne 'NO PLAN' ? $plan - $tests : 1;
        $ctx->skip($name)
          for 1 .. $skips;
        $ctx->note($skips ? $message : $full_message);
      }
      else {
        $ctx->plan(0, 'SKIP', $full_message);
      }
    }
    $ctx->done_testing;
    $ctx->release if $Test2::API::VERSION < 1.302053;
    $ctx->send_event('+'._t2_terminate_event());
  }
  elsif ($INC{'Test/Builder.pm'}) {
    my $tb = Test::Builder->new;
    my $has_plan = Test::Builder->can('has_plan') ? 'has_plan' : sub {
      $_[0]->expected_tests
        || eval { $_[0]->current_test($_[0]->current_test); 'no_plan' }
    };
    if ($fail) {
      $tb->plan(tests => 1)
        unless $tb->$has_plan;
      $tb->ok(0, $name);
      $tb->diag($message);
    }
    else {
      my $plan = $tb->$has_plan;
      my $tests = $tb->current_test;
      if ($plan || $tests) {
        my $skips
          = $plan && $plan ne 'no_plan' ? $plan - $tests : 1;
        $tb->skip($name)
          for 1 .. $skips;
        my $note = Test::Builder->can('note') ? 'note' : sub {
          my ($c, $m) = @_;
          $m =~ s/^/# /mg;
          $m =~ s/\n?\z/\n/;
          print { $c->output } $m;
        };
        $tb->$note($skips ? $message : $full_message);
      }
      else {
        $tb->skip_all($full_message);
      }
    }
    $tb->done_testing
      if Test::Builder->can('done_testing');
    die bless {} => 'Test::Builder::Exception'
      if Test::Builder->can('parent') && $tb->parent;
  }
  else {
    if ($fail) {
      print "1..1\n";
      print "not ok 1 - $name\n";
      print STDERR "# $message\n";
      exit 1;
    }
    else {
      print "1..0 # SKIP $full_message\n";
    }
  }
  exit 0;
}

my $terminate_event;
sub _t2_terminate_event () {
  return $terminate_event
    if $terminate_event;
  local $@;
  my $file = __FILE__;
  $terminate_event = eval <<"END_CODE" or die "$@";
    package # hide
      Test::Needs::Event::Terminate;
    use Test2::Event ();
    our \@ISA = qw(Test2::Event);
    sub no_display { 1 }
    sub terminate { 0 }
    \$INC{'Test/Needs/Event/Terminate.pm'} = \$file;
    __PACKAGE__;
END_CODE
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Test::Needs - Skip tests when modules not available

=head1 SYNOPSIS

  # need one module
  use Test::Needs 'Some::Module';

  # need multiple modules
  use Test::Needs 'Some::Module', 'Some::Other::Module';

  # need a given version of a module
  use Test::Needs {
    'Some::Module' => '1.005',
  };

  # check later
  use Test::Needs;
  test_needs 'Some::Module';

  # skips remainder of subtest
  use Test::More;
  use Test::Needs;
  subtest 'my subtest' => sub {
    test_needs 'Some::Module';
    ...
  };

  # check perl version
  use Test::Needs { perl => 5.020 };

=head1 DESCRIPTION

Skip test scripts if modules are not available.  The requested modules will be
loaded, and optionally have their versions checked.  If the module is missing,
the test script will be skipped.  Modules that are found but fail to compile
will exit with an error rather than skip.

If used in a subtest, the remainder of the subtest will be skipped.

Skipping will work even if some tests have already been run, or if a plan has
been declared.

Versions are checked via a C<< $module->VERSION($wanted_version) >> call.
Versions must be provided in a format that will be accepted.  No extra
processing is done on them.

If C<perl> is used as a module, the version is checked against the running perl
version (L<$]|perlvar/$]>).  The version can be specified as a number,
dotted-decimal string, v-string, or version object.

If the C<RELEASE_TESTING> environment variable is set, the tests will fail
rather than skip.  Subtests will be aborted, but the test script will continue
running after that point.

=head1 EXPORTS

=head2 test_needs

Has the same interface as when using Test::Needs in a C<use>.

=head1 SEE ALSO

=over 4

=item L<Test::Requires>

A similar module, with some important differences.  L<Test::Requires> will act
as a C<use> statement (despite its name), calling the import sub.  Under
C<RELEASE_TESTING>, it will BAIL_OUT if a module fails to load rather than
using a normal test fail.  It also doesn't distinguish between missing modules
and broken modules.

=item L<Test2::Require::Module>

Part of the L<Test2> ecosystem.  Only supports running as a C<use> command to
skip an entire plan.

=item L<Test2::Require::Perl>

Part of the L<Test2> ecosystem.  Only supports running as a C<use> command to
skip an entire plan.  Checks perl versions.

=item L<Test::If>

Acts as a C<use> statement.  Only supports running as a C<use> command to skip
an entire plan.  Can skip based on subref results.

=back

=head1 AUTHORS

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head1 CONTRIBUTORS

None so far.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016 the Test::Needs L</AUTHORS> and L</CONTRIBUTORS>
as listed above.

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
