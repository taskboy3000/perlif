# -*- cperl -*-
use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../../local/lib/perl5/", "$FindBin::Bin/../../lib");

use game;
use item;
use location;

my $game = game->get_instance;
init($game);

$game->run();

sub init {
  my ($game) = @_;
  $game->introduction("Welcome, foolish mortals, to my haunted mansion!  Find my funeral urn or stay trapped in here forever.\n");
  my $start = $game->firstLocation;
  $start->description("This small room has the door you came in to the north, which is not locked.  A small table supports a VASE.\n");
  $start->addItem(item->new(name => "VASE", description => "This vase is old, but cheap.\n"));

  my $parlor = location->new(name=>"parlor", description=> "Among the drear portraits of graceless, unhappy faces is a portrait of a mangy dog.\n");
  $start->addSouth($parlor);
  $parlor->addItem(item->new(name => "URN", description => "Even the tarnish on this urn looks old.\n", triggersGameOver => 1, gameOverText => "You captured the ghost's urn!\n", points => 10));
}
