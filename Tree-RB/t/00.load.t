use Test::More tests => 3;

BEGIN {
use lib 'C:\code\perl\.module-starter\Tree-RB\lib';
use_ok( 'Tree::RB' );
use_ok( 'Tree::RB::Node' );
use_ok( 'Tree::RB::Node::_Fields' );
}

diag( "Testing Tree::RB::Node::_Fields $Tree::RB::Node::_Fields::VERSION" );

foreach my $m (qw[
    _PARENT
    _LEFT
    _RIGHT
    _COLOR
    _KEY
    _VAL
    new
    key
    val
    color
    parent
    left
    right
    min
    max
    successor
    predecessor
  ])
{
    can_ok('Tree::RB::Node::_Fields', $m);
}


diag( "Testing Tree::RB $Tree::RB::VERSION" );

