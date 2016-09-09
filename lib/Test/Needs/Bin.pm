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
__END__

=pod

=encoding utf-8

=head1 NAME

Test::Needs::Bin - Skip tests when executable not available

=head1 SYNOPSIS

  use Test::Needs::Bin 'git', 'gpg';

  # check later
  use Test::Needs::Bin;
  test_needs_bin 'git';

  # skips remainder of subtest
  use Test::More;
  use Test::Needs::Bin;
  subtest 'my subtest' => sub {
    test_needs_bin 'git';
    ...
  };

=head1 DESCRIPTION

Skip test scripts if programs not available.  Skipping is done in the same
manner as L<Test::Needs>.

=head1 EXPORTS

=head2 test_needs_bin

Has the same interface as when using Test::Needs::Bin in a C<use>.

=head1 SEE ALSO

=over 4

=item L<Devel::CheckBin>

Meant for use in a Makefile.PL or Build.PL rather than test scripts.

=item L<Test::Skip::UnlessExistsExecutable>

Less compatible with ancient versions of Test::More, and doesn't promote skips
to failures under C<RELEASE_TESTING>.

=back

=head1 AUTHORS

See L<Test::Needs|Test::Needs/AUTHORS> for authors.

=head1 COPYRIGHT AND LICENSE

See L<Test::Needs|Test::Needs/COPYRIGHT AND LICENSE> for the copyright and
license.

=cut
