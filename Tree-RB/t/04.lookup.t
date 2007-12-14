use Test::More tests => 9;
use strict;
use warnings;

use Tree::RB qw[LUEQUAL LUGTEQ LULTEQ LUGREAT LULESS LUNEXT LUPREV];

diag( "Testing lookup in Tree::RB $Tree::RB::VERSION" );

my $tree = Tree::RB->new;

$tree->insert('France' => 'Paris');
$tree->insert('England' => 'London');
$tree->insert('Hungary' => 'Budapest');
$tree->insert('Ireland' => 'Dublin');
$tree->insert('Egypt' => 'Cairo');
$tree->insert('Germany' => 'Berlin');

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
$val = $tree->lookup('Germany');
is($val, 'Berlin', 'lookup');
$val = $tree->lookup('Belgium', LUGTEQ);
#use Data::Dumper;
#print Dumper($val)."\n";
is($val, 'Cairo', 'lookup LUGTEQ: left');

$val = $tree->lookup('Finland', LUGTEQ);
is($val, 'Paris', 'lookup LUGTEQ: right');

is('Budapest', $tree->lookup('Hungary', LULTEQ), 'lookup LULTEQ: node exists');
ok(!defined $tree->lookup('Belgium', LULTEQ), 'lookup LULTEQ: no lt node');
is($tree->lookup('Jamaica', LULTEQ), 'Dublin', 'lookup LULTEQ: right');
is($tree->lookup('Iceland', LULTEQ), 'Budapest', 'lookup LULTEQ: left');

is($tree->lookup('Belgium', LUGREAT), 'Cairo', 'lookup LUGREAT: left');
is($tree->lookup('Finland', LUGREAT), 'Paris', 'lookup LUGREAT: right');

