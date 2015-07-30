package Marathon::Group;

use strict;
use warnings;
use parent 'Marathon::Remote';

sub new {
    my ($class, $conf, $parent) = @_;
    my $self = bless {};
    $conf = {} unless $conf && ref $conf eq 'HASH';
    $self->{data} = $conf;
    $self->{parent} = $parent;
    $self->{children} = {
        apps => {},
        groups => {},
    };
    return $self;
}

sub list {
    my $self = shift;

}

sub create {
    my $self = shift;
    $self->_bail unless defined $self->{parent};
    return $self->{parent}->_post('/v2/groups', $self->get_updateable_values);
}

sub update {
    my $self = shift;
    $self->_bail unless defined $self->{parent};
    return $self->{parent}->_put('/v2/groups/' . $self->id, $self->get_updateable_values);
}

sub delete {
    my $self = shift;
    $self->_bail unless defined $self->{parent};
    return $self->{parent}->_delete('/v2/groups/' . $self->id);
}

sub add {
    my ($self, $child) = @_;
    if ( $child->isa('Marathon::App') ) {
        print STDERR "Add App: " . $self->id . ' :: ' . $child->id . "\n";
        if ( exists $self->{children}->{apps}->{$child->id} ) {
            print STDERR "You cannot add the same App twice.\n";
            return 0;
        }
        $self->{children}->{apps}->{$child->id} = $child;
    } elsif ( $child->isa('Marathon::Group') ) {
        print STDERR "Add Group: " . $self->id . ' :: ' . $child->id . "\n";
        if ( $self->is_or_has($child) ) {
            print STDERR "You cannot add a group to itself.\n";
            return 0;
        }
        $self->{children}->{groups}->{$child->id} = $child;
    } else {
        print STDERR "You cannot add something else than an App or a Group to a Group.\n";
        return 0;
    }
    return 1;
}

sub is_or_has {
    my ($self, $other) = @_;
    print STDERR "Compare: " . $self->id . ' :: ' . $other->id . "\n";
    if ( $self->id eq $other->id ) {
        return 1;
    }    
    foreach my $group ( values %{$self->{children}->{groups}} ) {
        return $group->is_or_has($other);
    }
    return 0;
}

1;
