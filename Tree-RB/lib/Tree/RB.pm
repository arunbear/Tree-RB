package Tree::RB;

use strict;
use Carp;

use Tree::RB::Node qw[set_color color_of parent_of left_of right_of];
use Tree::RB::Node::_Constants;

our $VERSION = '0.1';

use Exporter 'import';
our @EXPORT_OK = qw[LUEQUAL LUGTEQ LULTEQ LUGREAT LULESS LUNEXT LUPREV];

use Data::Dumper;
use constant {
    LUEQUAL => 0,
    LUGTEQ  => 1,
    LULTEQ  => 2,
    LUGREAT => 4,
    LULESS  => 5,
    LUNEXT  => 6,
    LUPREV  => 7,
};
use constant {
    ROOT  => 0,
    CMP   => 1,
    SIZE  => 2,
};

sub _mk_iter {
    my $start_fn = shift || 'min';
    my $next_fn  = shift || 'successor';
    return sub {
        my $self = shift;
        my $node;
        my $iter = sub {
            if($node) {
                $node = $node->$next_fn;
            }
            else {
                $node = $self->$start_fn;
            }
            return $node;
        };
        return bless($iter => 'Tree::RB::Iterator');
    };
}

*Tree::RB::Iterator::next = sub { $_[0]->() };

*iter     = _mk_iter(qw/min successor/);
*rev_iter = _mk_iter(qw/max predecessor/);

sub new {
    my ($class, $cmp) = @_;
    my $obj = [];
    $obj->[SIZE] = 0;
    if($cmp) {
        ref $cmp eq 'CODE'
          or croak('Invalid arg: codref expected');
        $obj->[CMP] = $cmp;
    }
    return bless $obj => $class;
}

*TIEHASH = \&new;

sub DESTROY { $_[0]->[ROOT]->DESTROY if $_[0]->[ROOT] }

sub resort {
    my $self = $_[0];
    my $cmp  = $_[1];
    ref $cmp eq 'CODE'
      or croak sprintf(q[Arg of type coderef required; got %s], ref $cmp || 'undef');

    my $new_tree = __PACKAGE__->new($cmp);
    $self->[ROOT]->strip(sub { $new_tree->insert($_[0]) });
    $new_tree->insert(delete $self->[ROOT]);
    $_[0] = $new_tree;
}

sub root { $_[0]->[ROOT] }
sub size { $_[0]->[SIZE] }

sub min {
    my $self = shift;
    return undef unless $self->[ROOT];
    return $self->[ROOT]->min;
}

sub max {
    my $self = shift;
    return undef unless $self->[ROOT];
    return $self->[ROOT]->max;
}

sub lookup {
    my $self = shift;
    my $key  = shift or croak('Missing arg: $key');
    my $mode = shift || LUEQUAL;
    my $cmp = $self->[CMP];

    my $y;
    my $x = $self->[ROOT];
    my $next_child;
    while($x) {
        $y = $x;
        if($cmp ? $cmp->($key, $x->[_KEY]) == 0
                : $key eq $x->[_KEY]) {
            # found it!
            if($mode == LUGREAT || $mode == LUNEXT) {
                $x = $x->successor;
            }
            elsif($mode == LULESS || $mode == LUPREV) {
                $x = $x->predecessor;
            }
            return wantarray
              ? ($x->[_VAL], $x)
              : $x->[_VAL];
        }
        if($cmp ? $cmp->($key, $x->[_KEY]) < 0
                : $key lt $x->[_KEY]) {
            $next_child = _LEFT;
        }
        else {
            $next_child = _RIGHT;
        }
        $x = $x->[$next_child];
    }
    # Didn't find it :(
    if($mode == LUGTEQ || $mode == LUGREAT) {
        if($next_child == _LEFT) {
            return wantarray ? ($y->[_VAL], $y) : $y->[_VAL];
        }
        else {
            my $next = $y->successor;
            return wantarray ? ($next->[_VAL], $next) : $next->[_VAL];
        }
    }
    elsif($mode == LULTEQ || $mode == LULESS) {
        if($next_child == _RIGHT) {
            return wantarray ? ($y->[_VAL], $y) : $y->[_VAL];
        }
        else {
            my $next = $y->predecessor;
            return wantarray ? ($next->[_VAL], $next) : $next->[_VAL];
        }
    }
    return;
}

*FETCH = \&lookup;

sub insert {
    my $self = shift;
    my $key_or_node = shift or croak('key or node required');
    my $val = shift;
    if(!$val && ref $key_or_node ne 'Tree::RB::Node') {
        croak('value required');
    }
    my $cmp = $self->[CMP];
    my $z = (ref $key_or_node eq 'Tree::RB::Node')
              ? $key_or_node
              : Tree::RB::Node->new($key_or_node => $val);

    my $y;
    my $x = $self->[ROOT];
    while($x) {
        $y = $x;
        # Handle case of inserting node with duplicate key.
        if($cmp ? $cmp->($z->[_KEY], $x->[_KEY]) == 0
                : $z->[_KEY] eq $x->[_KEY])
        {
            my $old_val = $x->[_VAL];
            $x->[_VAL] = $z->[_VAL];
            return $old_val;
        }
        if($cmp ? $cmp->($z->[_KEY], $x->[_KEY]) < 0
                : $z->[_KEY] lt $x->[_KEY])
        {
            $x = $x->[_LEFT];
        }
        else {
            $x = $x->[_RIGHT];
        }
    }
    # insert new node
    $z->[_PARENT] = $y;
    if(not defined $y) {
        $self->[ROOT] = $z;
    }
    else {
        if($cmp ? $cmp->($z->[_KEY], $y->[_KEY]) < 0
                : $z->[_KEY] lt $y->[_KEY])
        {
            $y->[_LEFT] = $z;
        }
        else {
            $y->[_RIGHT] = $z;
        }
    }
    $self->_fix_after_insertion($z);
    $self->[SIZE]++;
}

*STORE = \&insert;

sub _fix_after_insertion {
    my $self = shift;
    my $x = shift or croak('Missing arg: node');

    $x->[_COLOR] = RED;
    while($x != $self->[ROOT] && $x->[_PARENT][_COLOR] == RED) {
        my ($child, $rotate1, $rotate2);
        if(($x->[_PARENT] || 0) == ($x->[_PARENT][_PARENT][_LEFT] || 0)) {
            ($child, $rotate1, $rotate2) = (_RIGHT, '_left_rotate', '_right_rotate');
        }
        else {
            ($child, $rotate1, $rotate2) = (_LEFT, '_right_rotate', '_left_rotate');
        }
        my $y = $x->[_PARENT][_PARENT][$child];

        if($y && $y->[_COLOR] == RED) {
            $x->[_PARENT][_COLOR] = BLACK;
            $y->[_COLOR] = BLACK;
            $x->[_PARENT][_PARENT][_COLOR] = RED;
            $x = $x->[_PARENT][_PARENT];
        }
        else {
            if($x == ($x->[_PARENT][$child] || 0)) {
                $x = $x->[_PARENT];
                $self->$rotate1($x);
            }
            $x->[_PARENT][_COLOR] = BLACK;
            $x->[_PARENT][_PARENT][_COLOR] = RED;
            $self->$rotate2($x->[_PARENT][_PARENT]);
        }
    }
    $self->[ROOT][_COLOR] = BLACK;
}

sub delete {
    my $self = shift;
    my $key_or_node = shift or croak('key or node required');
    my $z = (ref $key_or_node eq 'Tree::RB::Node')
              ? $key_or_node
              : ($self->lookup($key_or_node))[1];
    return unless $z;

    my $y = ($z->[_LEFT] && $z->[_RIGHT])
              ? $z->successor
              : $z;
    # splice out $y
    my $x = $y->[_LEFT] || $y->[_RIGHT];
    if(defined $x) {
        $x->[_PARENT] = $y->[_PARENT];
        if(! defined $y->[_PARENT]) {
            $self->[ROOT] = $x;
        }
        elsif($y == $y->[_PARENT][_LEFT]) {
            $y->[_PARENT][_LEFT] = $x;
        }
        else {
            $y->[_PARENT][_RIGHT] = $x;
        }
        # Null out links so they are OK to use by _fix_after_deletion
        delete @{$y}[_PARENT, _LEFT, _RIGHT];

        # Fix replacement
        if($y->[_COLOR] == BLACK) {
            $self->_fix_after_deletion($x);
        }
    }
    elsif(! defined $y->[_PARENT]) {
        # return if we are the only node
        delete $self->[ROOT];
    }
    else {
        # No children. Use self as phantom replacement and unlink
        if($y->[_COLOR] == BLACK) {
            $self->_fix_after_deletion($y);
        }
        if(defined $y->[_PARENT]) {
            no warnings 'uninitialized';
            if($y == $y->[_PARENT][_LEFT]) {
                delete $y->[_PARENT][_LEFT];
            }
            elsif($y == $y->[_PARENT][_RIGHT]) {
                delete $y->[_PARENT][_RIGHT];
            }
            delete $y->[_PARENT];
        }
    }
    $self->[SIZE]--;
    return $y;
}

sub _fix_after_deletion {
    my $self = shift;
    my $x = shift or croak('Missing arg: node');

    while($x != $self->[ROOT] && color_of($x) == BLACK) {
        my ($child1, $child2, $rotate1, $rotate2);
        no warnings 'uninitialized';
        if($x == left_of(parent_of($x))) {
            ($child1,    $child2,   $rotate1,       $rotate2) =
            (\&right_of, \&left_of, '_left_rotate', '_right_rotate');
        }
        else {
            ($child1,   $child2,    $rotate1,        $rotate2) =
            (\&left_of, \&right_of, '_right_rotate', '_left_rotate');
        }
        use warnings;

        my $w = $child1->(parent_of($x));
        if(color_of($w) == RED) {
            set_color($w, BLACK);
            set_color(parent_of($x), RED);
            $self->$rotate1(parent_of($x));
            $w = right_of(parent_of($x));
        }
        if(color_of($child2->($w)) == BLACK &&
           color_of($child1->($w)) == BLACK) {
            set_color($w, RED);
            $x = parent_of($x);
        }
        else {
            if(color_of($child1->($w)) == BLACK) {
                set_color($child2->($w), BLACK);
                set_color($w, RED);
                $self->$rotate2($w);
                $w = $child1->(parent_of($x));
            }
            set_color($w, color_of(parent_of($x)));
            set_color(parent_of($x), BLACK);
            set_color($child1->($w), BLACK);
            $self->$rotate1(parent_of($x));
            $x = $self->[ROOT];
        }
    }
    set_color($x, BLACK);
}

sub _left_rotate {
    my $self = shift;
    my $x = shift or croak('Missing arg: node');

    my $y = $x->[_RIGHT]
      or return;
    $x->[_RIGHT] = $y->[_LEFT];
    if($y->[_LEFT]) {
        $y->[_LEFT]->[_PARENT] = $x;
    }
    $y->[_PARENT] = $x->[_PARENT];
    if(not defined $x->[_PARENT]) {
        $self->[ROOT] = $y;
    }
    else {
        $x == $x->[_PARENT]->[_LEFT]
          ? $x->[_PARENT]->[_LEFT]  = $y
          : $x->[_PARENT]->[_RIGHT] = $y;
    }
    $y->[_LEFT]   = $x;
    $x->[_PARENT] = $y;
}

sub _right_rotate {
    my $self = shift;
    my $y = shift or croak('Missing arg: node');

    my $x = $y->[_LEFT]
      or return;
    $y->[_LEFT] = $x->[_RIGHT];
    if($x->[_RIGHT]) {
        $x->[_RIGHT]->[_PARENT] = $y
    }
    $x->[_PARENT] = $y->[_PARENT];
    if(not defined $y->[_PARENT]) {
        $self->[ROOT] = $x;
    }
    else {
        $y == $y->[_PARENT]->[_RIGHT]
          ? $y->[_PARENT]->[_RIGHT] = $x
          : $y->[_PARENT]->[_LEFT]  = $x;
    }
    $x->[_RIGHT] = $y;
    $y->[_PARENT] = $x;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Tree::RB - [One line description of module's purpose here]


=head1 VERSION

This document describes Tree::RB version 0.0.1


=head1 SYNOPSIS

    use Tree::RB;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.


=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.

Tree::RB requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-tree-rb@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Arun Prasad  C<< <arunbear@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Arun Prasad C<< <arunbear@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
