#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 35;

# TEST DATA
my $api_url         = 'http://localhost:8080';
my $organization    = 'test-organization';
my $application     = 'test-app';
my $username        = 'testuser';
my $password        = 'Testuser123$';
###########

my ($user, $token, $book, $collection, $count);

BEGIN {
  use_ok 'Usergrid::Client'     || print "Bail out!\n";
}

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

eval {

  $collection = $client->get_collection("books");

  ok ( $collection->count() == 0, "count must be initially zero" );

  for (my $i = 0; $i < 30; $i++) {
    $client->add_entity("books", { name => "book $i", index => $i });
  }

  $collection = $client->get_collection("books", 30);

  ok ( $collection->count() == 30, "count must now be 30" );

  $client->update_collection("books", { in_stock => 1 });

  $collection = $client->get_collection("books", 30);

  while ($collection->has_next_entity()) {
    $book = $collection->get_next_entity();
    ok ( $book->get('in_stock') == 1 );
  }

  $client->update_collection("books", { in_stock => 0 }, "select * where index = '1' or index = '2' or index = '3' or index = '4' or index = '5'");

  $collection = $client->get_collection("books", 30);

  while ($collection->has_next_entity()) {
    $book = $collection->get_next_entity();
    $count++ if ($book->get('index') =~ /[12345]/ && $book->get('in_stock') == 0);
    $client->delete_entity($book);
  }

  ok ( $count == 5, "batch update only 5 entities" );

  $collection = $client->get_collection("books");

  ok ( $collection->count() == 0, "count must now be again zero" );

};

diag($@) if $@;

# Cleanup
$client->delete_entity($user);