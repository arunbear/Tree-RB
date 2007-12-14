use Test::More tests => 2;
use strict;
use warnings;

use Tree::RB;

diag( "Testing tied hash interface in Tree::RB $Tree::RB::VERSION" );

my %capital;
my $tied = tie(%capital, 'Tree::RB');

isa_ok($tied, 'Tree::RB');

$capital{'France'} = 'Paris';

is($capital{'France'}, 'Paris', 'STORE and FETCH work');

