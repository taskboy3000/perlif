# -*- cperl -*-
use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../local/lib/perl5/", "$FindBin::Bin/../lib");

use Test::More;

use game;
use location;
use item;

# constructor

my $L = location->new(name=>"room1");
ok($L, "Object creation");

my $L2 = location->new(name => "room2", description => "This room is terrible and green.");
ok($L->addNorth($L2), sprintf("Added '%s' as a north exit to '%s'", $L2->name, $L->name));

ok(keys %{ $L->exits } == 1, sprintf("One exit defined for room '%s': %s", $L->name, keys %{$L->exits}));
ok(keys %{ $L2->exits } == 1, sprintf("One exit defined for room '%s': %s", $L2->name, keys %{$L2->exits}));

my $I = item->new(name => "pointy knife", description => "This is one pointy knife.");
ok($L->addItem($I), sprintf("Adding %s to room %s", $I->name, $L->name));

printf("%s\n", $L->look);

ok($L->take($I), "Take " . $I->name);

printf("%s\n", $L->look);

printf("Location verbs: %s\n", join(", ", map { uc } sort keys %{ $L->verbs }));
ok($L->look, sprintf("%s: look", $L->name));
my $rc = eval {
  $L->go('n');
  1;
};

ok(!$rc, "Caught illegal move");
my $msg = $L->go("north");
ok($msg, "Moved north: $msg");


done_testing();
