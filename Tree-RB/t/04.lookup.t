use Test::More tests => 7;
use strict;
use warnings;

use Tree::RB;

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

my ($val, $count);
$val = $tree->lookup('Germany');
is($val, 'Berlin', 'lookup');
($val, undef, $count) = $tree->lookup('France');
is($count, 1, 'lookup root - count nodes scanned');

($val, undef, $count) = $tree->lookup('Germany');
is($count, 3, 'lookup non root - count nodes scanned');

#ok(! defined $node, 'lookup deleted node');
#ok(! defined $val,  q[lookup deleted node's value]);
