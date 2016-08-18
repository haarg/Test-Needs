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

sub _find_missing {
  my $class = shift;
  return "NO_NETWORK_TESTING set" if $ENV{NO_NETWORK_TESTING};
  my @bad = map {
    my ($host, $port) = @$_;
    eval { _assert_socket($host, $port) } ? () : do {
      my $e = $@;
      $e =~ s/\n\z//;
      "$host:$port ($e)";
    };
  } (@_ == 1 && ref $_[0] eq 'HASH')
    ? (map [$_ => $_[0]{$_}], sort keys %{$_[0]})
    : map [ $_ =~ /:/ ? split /:/, $_ : $_ => 80 ], @_;
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

1;
