#!/usr/bin/perl
use strict;
use warnings;
use Usergrid::Client;
use IO::Socket::INET;
use Test::More;
use Data::Dumper;

# TEST DATA
our $hostname        = 'localhost';
our $port            = '8080';
our $api_url         = "http://$hostname:$port";
our $organization    = 'test-organization';
our $application     = 'test-app';
our $username        = 'superuser';
our $password        = 'superuser';
###########

if (_check_port($hostname, $port)) {
  plan tests => 4;
} else {
  plan skip_all => "server $api_url not reachable"
}

sub _check_port {
  my ($hostname, $port) = @_;
  new IO::Socket::INET ( PeerAddr => $hostname, PeerPort => $port,
    Proto => 'tcp' ) || return 0;
  return 1;
}

my ($collection, $token, $result);

# Create the client object that will be used for all subsequent requests
my $client = Usergrid::Client->new(
  organization => $organization,
  application  => $application,
  api_url      => $api_url,
  trace        => 0
);

$token = $client->admin_login($username, $password);

$result = eval {
  $collection = $client->get_collection("books");
};

ok ( $@ eq '', "no errors during admin login" );

ok ( $token->{user}->{username} eq $username, "user logged in" );

$result = $client->admin_logout();

ok ( $result->{'action'} =~ /revoked/, "admin token revoked" );

$result = eval {
  $collection = $client->get_collection("books");
};

ok ( $@ =~ /Unauthorized/, "successful logout" );
