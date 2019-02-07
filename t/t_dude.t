# -*- cperl -*-
use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../local/lib/perl5/", "$FindBin::Bin/../lib");

use Test::More;

use dude;
use item;

# constructor
my $PC = dude->new;
ok($PC, "creation");
printf("%s\n", $PC->score);
printf("Inv: %s\n", $PC->inventory);

my $I = item->new(name => "pointy knife", description => "This is one pointy knife.");
ok($PC->addItem($I), "Add item: " . $I->name);
printf("Inv: %s\n", $PC->inventory);

my $rc = eval { $PC->addItem($I); 1; };
ok(!$rc, "Correctly blocked re-add: " . $@);

done_testing();
