use strict;
use warnings;
use Test::More tests => 4 + 21*2;
use IPC::Open3;

delete $ENV{RELEASE_TESTING};

my @perl = ($^X, map "-I$_", @INC, 't/lib');

my $missing = "Module::Does::Not::Exist::".time;

sub capture {
  my $pid = open3 my $stdin, my $stdout, undef, @_
    or die "can't run perl: $!";
  my $out = do { local $/; <$stdout> };
  close $stdout;
  waitpid $pid, 0;
  my $exit = $?;
  return ($exit, $out);
}

my $apis = {
  standalone => {
    testable => sub { 1 },
    script_args => [],
  },
  Test2 => {
    testable => sub {
      eval { require Test2::API;       1 } or die "Test2::API not available";
      eval { Test2::API->VERSION(1.3); 1 } or die "Test2::API version not new enough for this test";
    },
    script_args => [ '--load=Test2::API' ],
  },
  'Test::Builder' => {
    testable => sub {
      eval { require Test::Builder; 1 } or die "Test::Builder not available";
    },
    script_args => [ '--load=Test::Builder' ],
  },
};

for my $label ('standalone','Test2','Test::Builder') {
  SKIP: {
    my $api = $apis->{ $label };

    local $@;
    eval { $api->{testable}->(); 1 } or skip "$label not testable, $@", 21;

    my $check = sub {
      my ($args, $match, $name) = @_;
      my @args = (@{$api->{script_args}}, @$args);
      my ($exit, $out)
        = capture @perl, '-MTestScript' . (@args ? '='.join(',', @args) : '');
      $name .= " ($label)";
      my $want_exit;
      if (ref $match eq 'HASH') {
        $want_exit = $match->{exit};
        $match = $match->{match};
      }
      my @match = ref $match eq 'ARRAY' ? @$match : $match ? $match : ();
      if ($exit && !$want_exit) {
        ok 0, $name;
        diag "Exit status $exit\nOutput:\n$out";
      }
      else {
        for my $m (@match) {
          like $out, $m, $name;
        }
      }
    };

    $check->(
      [$missing],
      qr/^1\.\.0 # SKIP/i,
      'Missing module SKIPs',
    );
    $check->(
      ['BrokenModule'],
      { match => qr/syntax error/, exit => 1 },
      'Broken module dies',
    );
    $check->(
      ['ModuleWithVersion'],
      qr/^(?!1\.\.0 # SKIP)/i,
      'Working module runs',
    );
    $check->(
      ['ModuleWithVersion', 2],
      qr/^1\.\.0 # SKIP/i,
      'Outdated module SKIPs',
    );
    next
      unless @{ $api->{script_args} };

    $check->(
      [$missing, '--plan'],
      qr/# skip/,
      'Missing module skips with plan',
    );
    $check->(
      [$missing, '--no_plan'],
      qr/# skip/,
      'Missing module skips with no_plan',
    );
    SKIP: {
      skip 'Test::More too old to run tests without plan', 1
        if !Test::More->can('done_testing');
      $check->(
        [$missing, '--tests'],
        qr/# skip/,
        'Missing module skips with tests',
      );
    }
    $check->(
      [$missing, '--plan', '--tests'],
      qr/# skip/,
      'Missing module passes with plan and tests',
    );
    $check->(
      [$missing, '--no_plan', '--tests'],
      qr/# skip/,
      'Missing module passes with no_plan and tests',
    );

    SKIP: {
      skip 'Test::More too old to run subtests', 12
        if !Test::More->can('subtest');

      $check->(
        [$missing, '--subtest'],
        [ qr/^ +1\.\.0 # SKIP/mi, qr/^[^ ][^\n]+# skip/m ],
        'Missing module skips in subtest',
      );
      $check->(
        ['BrokenModule', '--subtest'],
        { match => qr/syntax error/, exit => 1 },
        'Broken module dies in subtest',
      );
      $check->(
        ['ModuleWithVersion', '--subtest'],
        [ qr/^ +1\.\.(?!0 # SKIP)/mi, qr/^ok[^\n#]+(?!# skip)/m ],
        'Working module runs in subtest',
      );
      $check->(
        ['ModuleWithVersion', 2, '--subtest'],
        [ qr/^ +1\.\.0 # SKIP/mi, qr/^[^ ][^\n]+# skip/m ],
        'Outdated module skips in subtest',
      );

      $check->(
        [$missing, '--subtest', '--plan'],
        qr/# skip/,
        'Missing module skips with plan in subtest',
      );
      $check->(
        [$missing, '--subtest', '--no_plan'],
        qr/# skip/,
        'Missing module skips with no_plan in subtest',
      );
      $check->(
        [$missing, '--subtest', '--tests'],
        qr/# skip/,
        'Missing module skips with tests in subtest',
      );
      $check->(
        [$missing, '--subtest', '--plan', '--tests'],
        qr/# skip/,
        'Missing module passes with plan and tests in subtest',
      );
      $check->(
        [$missing, '--subtest', '--no_plan', '--tests'],
        qr/# skip/,
        'Missing module passes with no_plan and tests in subtest',
      );
    }
  }
}
