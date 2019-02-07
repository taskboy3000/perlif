# -*- cperl -*-
use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../local/lib/perl5/", "$FindBin::Bin/../lib");

use Test::More;

use item;

# constructor
my $I = item->new(name => 'knife');
ok($I, "Item " . $I->name);
ok($I->description, "description");

printf("Item verbs: %s\n", join(", ", map { uc } sort keys %{ $I->verbs }));
ok($I->examine, sprintf("%s: %s", $I->name, $I->examine));

done_testing();
