use Test::More tests => 7;
use strict;
use warnings;

use Tree::RB;

diag( "Testing deletion in Tree::RB $Tree::RB::VERSION" );

my $tree = Tree::RB->new;

$tree->insert('England' => 'London');

my $size = $tree->size;

$tree->delete('England');

ok($size - $tree->size == 1, 'size goes down by one on removing a node');

my ($val, $node) = $tree->lookup('England');

ok(! defined $node, 'lookup deleted node');
ok(! defined $val,  q[lookup deleted node's value]);

$tree->insert('France' => 'Paris');
$tree->insert('England' => 'London');
$tree->insert('Hungary' => 'Budapest');
$tree->insert('Ireland' => 'Dublin');
$tree->insert('Egypt' => 'Cairo');

#               |
#          <B:France>
#       /--------------\
#       |              |
#  <B:England>    <B:Hungary>
#     /------\   /-------\
#     |      |   |       |
# <R:Egypt> <*> <*> <R:Ireland>
#   /---\              /---\
#   |   |              |   |
#  <*> <*>            <*> <*>

$tree->delete('Egypt');
is($tree->min->key,  'England', q[new min after deleting current min]);
is($tree->max->key,  'Ireland', q[max not changed after deleting current min]);

#              |
#         <B:France>
#      /-------------\
#      |             |
# <B:England>   <B:Hungary>
#    /---\     /-------\
#    |   |     |       |
#   <*> <*>   <*> <R:Ireland>
#                    /---\
#                    |   |
#                   <*> <*>

$tree->delete('Ireland');
is($tree->max->key,  'Hungary', q[new max after deleting current max]);
is($tree->min->key,  'England', q[min not changed after deleting current max]);

#            |
#       <B:France>
#      /-----------\
#      |           |
# <B:England> <B:Hungary>
#    /---\       /---\
#    |   |       |   |
#   <*> <*>     <*> <*>