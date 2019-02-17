package Test::Needs::Internet;
use strict;
use warnings;
no warnings 'once';
our $VERSION = '0.002004';
$VERSION =~ tr/_//d;

use Test::Needs ();
our @ISA = qw(Test::Needs);

use IO::Socket ();
use Socket ();

sub getaddrinfo;
BEGIN {
  if (defined &Socket::getaddrinfo) {
    *getaddrinfo = \&Socket::getaddrinfo;
  }
  else {
    eval <<'END_CODE' or die $@;
sub getaddrinfo {
  my ($node, $service, $hints) = @_;

  my $port = $service =~ /\D/ ? getservbyname($service, "tcp") : $service
    or return "Invalid port";

  my ( $name, undef, undef, undef, @addrs ) = gethostbyname( $node );
  return "Unresolvable host"
    if !$name;

  return (undef, map +{
    family    => Socket::AF_INET,
    socktype  => Socket::SOCK_STREAM,
    protocol  => Socket::IPPROTO_TCP,
    addr      => Socket::pack_sockaddr_in( $port, $_ ),
    canonname => undef,
  }, @addrs);
}
END_CODE
  }
}

our @EXPORT = qw(test_needs_internet);

sub _croak;
*_croak = \&Test::Needs::_croak;
sub _to_pairs;
*_to_pairs = \&Test::Needs::_to_pairs;

sub _find_missing {
  my $class = shift;
  return "NO_NETWORK_TESTING set"
    if $ENV{NO_NETWORK_TESTING};
  my @bad =
    map {
      my ($host, $port) = @$_;
      eval { _assert_socket($host, $port) } ? () : do {
        my $e = $@;
        $e =~ s/\n\z//;
        "$host:$port ($e)";
      };
    }
    map +(
      @$_ == 1 ? [ $_->[0] =~ /(.*):(.*)/ ? ($1, $2) : ($_->[0], 80) ] : $_
    ), _to_pairs(@_);
  @bad ? "Can't connect to " . join(', ', @bad) : undef;
}

sub _assert_socket {
  my ($host, $port) = @_;
  my ($err, @result)
    = getaddrinfo($host, $port, { socktype => Socket::SOCK_STREAM });
  die "$err\n" if $err;

  my $sock;
  my $sock_err;
  my $connect_err;
  foreach my $res (@result) {
    my $trysock = IO::Socket->new;
    $trysock->socket($res->{family}, $res->{socktype}, $res->{protocol})
      or ($sock_err = "socket: $!"), next;
    $trysock->timeout(1);

    $trysock->connect($res->{addr})
      or ($connect_err = "connect: $!"), next;

    $sock = $trysock;
    last;
  }
  die( ($connect_err || $sock_err )."\n" )
    if !$sock;

  $sock->close
    or die "close: $!\n";

  1;
}

sub test_needs_internet {
  local $Test::Builder::Level = ($Test::Builder::Level||0) + 1;
  __PACKAGE__->_needs(@_);
}

sub _needs_name { "Internet sites" }

sub _promote_to_failure {
  !$ENV{NO_NETWORK_TESTING} && $_[0]->SUPER::_promote_to_failure;
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Test::Needs::Internet - Skip tests when internet access is not available

=head1 SYNOPSIS

  use Test::Needs::Internet
    'www.google.com',               # check http
    'www.google.com:443',           # check https
    {
      'www.google.com' => 80,       # specify ports as hashref
      'www.google.com' => 'https',  # port can be given by name
    },
  ;

  # check later
  use Test::Needs::Internet;
  test_needs_internet 'www.google.com';

  # skips remainder of subtest
  use Test::More;
  use Test::Needs::Internet;
  subtest 'my subtest' => sub {
    test_needs_internet 'www.google.com';
    ...
  };

=head1 DESCRIPTION

Skip test scripts if the listed host names can't be connected to via TCP.
Skipping is done in the same manner as L<Test::Needs>.

If C<NO_NETWORK_TESTING> is set, tests will be skipped without testing any sites.

=head1 EXPORTS

=head2 test_needs_internet

Has the same interface as when using Test::Needs::Internet in a C<use>.

=head1 SEE ALSO

=over 4

=item L<Test::Internet>

Checks for access by querying the root DNS servers.  Does not respect
C<NO_NETWORK_TESTING>.

=item L<Test::RequiresInternet>

Limited to performing a C<skip_all>, and only works with IPv4.

=back

=head1 AUTHORS

See L<Test::Needs|Test::Needs/AUTHORS> for authors.

=head1 COPYRIGHT AND LICENSE

See L<Test::Needs|Test::Needs/COPYRIGHT AND LICENSE> for the copyright and
license.

=cut
