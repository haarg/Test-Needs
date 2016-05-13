package Test::Needs;
use strict;
use warnings;
our $VERSION = '0.001003';
$VERSION =~ tr/_//d;

sub import {
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Test::Needs - Skip tests when modules not available

=head1 SYNOPSIS

  use Test::Needs (
    'Some::Module' => '1.005',
  );

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
