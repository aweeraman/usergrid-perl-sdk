#!/usr/bin/perl
use strict;
use warnings;
use Usergrid::Client;
use IO::Socket::INET;
use Test::More;

# TEST DATA
our $hostname        = 'localhost';
our $port            = '8080';
our $api_url         = "http://$hostname:$port";
our $organization    = 'test-organization';
our $application     = 'test-app';
our $username        = 'testuser';
our $password        = 'Testuser123$';
###########

if (_check_port($hostname, $port)) {
  plan tests => 3;
} else {
  plan skip_all => "server $api_url not reachable"
}

sub _check_port {
  my ($hostname, $port) = @_;
  new IO::Socket::INET ( PeerAddr => $hostname, PeerPort => $port,
    Proto => 'tcp' ) || return 0;
  return 1;
}

my ($user, $token, $return);

# Create the client object that will be used for all subsequent requests
my $client = Usergrid::Client->new(
  organization => $organization,
  application  => $application,
  api_url      => $api_url,
  trace        => 0
);

# Create a test user
$user = $client->add_entity("users", { username=>$username, password=>$password });

$token = $client->login($username, $password);

ok ( $token->{user}->{username} eq $username, "user logged in" );

$client->logout();

# Should return undef if the user is deleted
$return = eval {
  $client->delete_entity($user);
};

ok ( ! defined $return, "did not log out properly");

ok ( $client->logout() == 0, "logout returns null if user is already logged out");

$client->login($username, $password);

$client->delete_entity($user);
