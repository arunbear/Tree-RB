use Test::More tests => 3;
use strict;
use warnings;

use_ok( 'Tree::RB' );

diag( "Testing Tree::RB $Tree::RB::VERSION" );

foreach my $m (qw[
    new
    insert
  ])
{
    can_ok('Tree::RB', $m);
}



__END__

my $node = Tree::RB::Node->new('England' => 'London');
isa_ok( $node, 'Tree::RB::Node' );
is($node->key, 'England', 'key retrieved after new');
is($node->val, 'London',  'value retrieved after new');

$node->key('France');
is($node->key, 'France', 'key retrieved after set');

$node->val('Paris');
is($node->val, 'Paris', 'value retrieved after set');

$node->color(1);
is($node->color, 1, 'color retrieved after set');

my $left_node  = Tree::RB::Node->new('England' => 'London');
$left_node->parent($node);
$node->left($left_node);
is($node->left, $left_node, 'left retrieved after set');

my $right_node = Tree::RB::Node->new('Hungary' => 'Budapest');
$right_node->parent($node);
$node->right($right_node);
is($node->right, $right_node, 'right retrieved after set');

my $parent_node = Tree::RB::Node->new('Ireland' => 'Dublin');
$parent_node->left($node);
$node->parent($parent_node);
is($node->parent, $parent_node, 'parent retrieved after set');

is($parent_node->min->key, 'England', 'min');

is($node->max->key, 'Hungary', 'max');
is($right_node->successor->key, 'Ireland', 'successor');
is($parent_node->predecessor->key, 'Hungary', 'predecessor');