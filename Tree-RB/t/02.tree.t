use Test::More tests => 8;
use strict;
use warnings;

use_ok( 'Tree::RB' );

diag( "Testing Tree::RB $Tree::RB::VERSION" );

foreach my $m (qw[
    new
    insert
    iter
    size
  ])
{
    can_ok('Tree::RB', $m);
}

my $tree = Tree::RB->new;
isa_ok($tree, 'Tree::RB');
ok($tree->size == 0, 'New tree has size zero');

$tree->insert('France'  => 'Paris');
$tree->insert('England' => 'London');
$tree->insert('Hungary' => 'Budapest');
$tree->insert('Ireland' => 'Dublin');
$tree->insert('Egypt'   => 'Cairo');
$tree->insert('Germany' => 'Berlin');

ok($tree->size == 6, 'size check after inserts');

my $it = $tree->iter;
isa_ok($it, 'Tree::RB::Iterator');
can_ok($it, 'next');

my $node;

$node = $it->next;
ok($node->key eq 'Egypt' && $node->val eq 'Cairo', 'iterator check');

$node = $it->next;
ok($node->key eq 'England' && $node->val eq 'London', 'iterator check');

$node = $it->next;
ok($node->key eq 'France' && $node->val eq 'Paris', 'iterator check');

$node = $it->next;
ok($node->key eq 'Germany' && $node->val eq 'Berlin', 'iterator check');

$node = $it->next;
ok($node->key eq 'Hungary' && $node->val eq 'Budapest', 'iterator check');

$node = $it->next;
ok($node->key eq 'Ireland' && $node->val eq 'Dublin', 'iterator check');

$node = $it->next;
ok(!defined $node, 'iterator check - no more items');

