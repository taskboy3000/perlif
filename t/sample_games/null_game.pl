# -*- cperl -*-
use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../../local/lib/perl5/", "$FindBin::Bin/../../lib");

use game;

game->get_instance->run();
