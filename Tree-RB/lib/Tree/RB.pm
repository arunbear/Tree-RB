package Tree::RB;

#use warnings;
use strict;
use Carp;

use Tree::RB::Node;
use Tree::RB::Node::_Fields;

use version; our $VERSION = qv('0.0.3');

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
    BLACK => 0,
    RED   => 1,
    ROOT  => 0,
    CMP   => 1,
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
    if($cmp) {
        ref $cmp eq 'CODE'
          or croak('Invalid arg: codref expected');
        $obj->[CMP] = $cmp;
    }
    return bless $obj => $class;
}

sub DESTROY { $_[0]->[ROOT]->DESTROY if $_[0]->[ROOT] }

sub root { $_[0]->[ROOT] }

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

sub find {
    my $self = shift;
    my $key  = shift or croak('Missing arg: $key');
    my $mode = shift || LUEQUAL;
    my $cmp = $self->[CMP];

    my $y;
    my $x = $self->[ROOT];
    my $depth = 0;
    my $next_child;
    while($x) {
        $y = $x;
        $depth++;
        if($cmp ? $cmp->($key, $x->[_KEY]) == 0
                : $key eq $x->[_KEY])
        {
            # found it!
            return wantarray
              ? ($x->[_VAL], $x, $depth)
              : $x->[_VAL];
        }
        if($cmp ? $cmp->($key, $x->[_KEY]) < 0
                : $key lt $x->[_KEY])
        {
            $next_child = _LEFT;
        }
        else {
            $next_child = _RIGHT;
        }
        $x = $x->[$next_child];
    }
    # Didn't find it :(
    if($mode == LUGTEQ) {
        if($next_child == _LEFT) {
            return ($y->[_VAL], $y, $depth);
        }
        else {
            my ($next, $count) = $y->successor;
            return ($next->[_VAL], $next, $depth+$count);
        }
    }
    return (undef, undef, $depth);
}

sub insert {
    my $self = shift;
    my $key  = shift or croak('Missing arg: $key');
    my $val  = shift or croak('Missing arg: $val');
    my $cmp = $self->[CMP];

    my $y;
    my $x = $self->[ROOT];
    while($x) {
        $y = $x;
        # Handle case of inserting node with duplicate key.
        if($cmp ? $cmp->($key, $x->[_KEY]) == 0
                : $key eq $x->[_KEY])
        {
            my $old_val = $x->[_VAL];
            $x->[_VAL] = $val;
            return $old_val;
        }
        if($cmp ? $cmp->($key, $x->[_KEY]) < 0
                : $key lt $x->[_KEY])
        {
            $x = $x->[_LEFT];
        }
        else {
            $x = $x->[_RIGHT];
        }
    }
    # insert new node
    my $z = Tree::RB::Node->new($key => $val);
    $z->[_PARENT] = $y;
    if(not defined $y) {
        $self->[ROOT] = $z;
    }
    else {
        if($cmp ? $cmp->($key, $y->[_KEY]) < 0
                : $key lt $y->[_KEY])
        {
            $y->[_LEFT] = $z;
        }
        else {
            $y->[_RIGHT] = $z;
        }
    }
    $self->_insert_fixup($z);
}

sub _insert_fixup {
    my $self = shift;
    my $x = shift or croak('Missing arg: node');

    $x->[_COLOR] = RED;
    while($x != $self->[ROOT] && $x->[_PARENT][_COLOR] == RED) {
        my ($child, $rotate1, $rotate2);
        if($x->[_PARENT] == $x->[_PARENT][_PARENT][_LEFT]) {
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
            if($x == $x->[_PARENT][$child]) {
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

sub _left_rotate {
    my $self = shift;
    my $x = shift or croak('Missing arg: node');

    my $y = $x->[_RIGHT];
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

    my $x = $y->[_LEFT];
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
