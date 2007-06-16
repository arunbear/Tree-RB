use Test::More tests => 7;
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



#ok(! defined $node, 'lookup deleted node');
#ok(! defined $val,  q[lookup deleted node's value]);
