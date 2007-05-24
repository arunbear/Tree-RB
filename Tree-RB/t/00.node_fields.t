use Test::More tests => 7;

use_ok( 'Tree::RB::Node::_Fields' );
diag( "Testing Tree::RB::Node::_Fields $Tree::RB::Node::_Fields::VERSION" );

foreach my $m (qw[
    _PARENT
    _LEFT
    _RIGHT
    _COLOR
    _KEY
    _VAL
  ])
{
    can_ok('Tree::RB::Node::_Fields', $m);
}