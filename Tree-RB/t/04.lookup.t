use Test::More tests => 10;
use strict;
use warnings;
use Data::Dumper;

use Tree::RB qw[LUEQUAL LUGTEQ LULTEQ LUGREAT LULESS LUNEXT LUPREV];

diag( "Testing lookup in Tree::RB $Tree::RB::VERSION" );

my $tree = Tree::RB->new;

$tree->put('France' => 'Paris');
$tree->put('England' => 'London');
$tree->put('Hungary' => 'Budapest');
$tree->put('Ireland' => 'Dublin');
$tree->put('Egypt' => 'Cairo');
$tree->put('Germany' => 'Berlin');

#                   |
#              <B:France>
#       /------------------\
#       |                  |
#  <B:England>        <B:Hungary>
#     /------\       /-----------\
#     |      |       |           |
# <R:Egypt> <*> <R:Germany> <R:Ireland>
#   /---\          /---\       /---\
#   |   |          |   |       |   |
#  <*> <*>        <*> <*>     <*> <*>

my $val;
my $node;
$val = $tree->lookup('Germany');
is($val, 'Berlin', 'lookup');
$val = $tree->lookup('Belgium', LUGTEQ);
is($val, 'Cairo', 'lookup LUGTEQ: left');

$val = $tree->lookup('Finland', LUGTEQ);
is($val, 'Paris', 'lookup LUGTEQ: right');

($val, $node) = $tree->lookup('Russia', LUGTEQ);
is_deeply($node, undef, 'lookup LUGTEQ: no gt node')
  or diag('got: '. Dumper($node));

is('Budapest', $tree->lookup('Hungary', LULTEQ), 'lookup LULTEQ: node exists');

($val, $node) = $tree->lookup('Belgium', LULTEQ);
is_deeply($node, undef, 'lookup LULTEQ: no lt node')
  or diag('got: '. Dumper($node));

is($tree->lookup('Jamaica', LULTEQ), 'Dublin', 'lookup LULTEQ: right');
is($tree->lookup('Iceland', LULTEQ), 'Budapest', 'lookup LULTEQ: left');

is($tree->lookup('Belgium', LUGREAT), 'Cairo', 'lookup LUGREAT: left');
is($tree->lookup('Finland', LUGREAT), 'Paris', 'lookup LUGREAT: right');

