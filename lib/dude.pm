package dude;
use strict;
use warnings;

use Moo;

has myScore => (is => 'rw', default => sub { 0 });
has items => (is => 'rw', default => sub { [] });
has location => (is => 'rw');

# Item handling
sub hasItems {
    my ($self) = @_;
    return @{$self->items} > 0;
}

sub hasItem {
    my ($self, $item) = @_;
    return unless $item;

    my $itemName = ref $item ? $item->name : "$item";

    for my $i (@{$self->items}) {
        if ($i->name eq $itemName) {
            return $i;
        }
    }

    return;
}

sub removeItem {
    my ($self, $item) = @_;
    return if !$self->hasItem($item);

    my @tmp;
    for my $i (@{$self->items}) {
        if ($i->name eq $item->name) {
            next;
        }
        push @tmp, $i;
    }

    @{ $self->items } = @tmp;
    
    return 1;
}

sub addItem {
    my ($self, $item) = @_;
    return unless $item;

    # Do not allow the re-adding of an item
    if ($self->hasItem($item)) {
        die("You already have " . $item->name . "\n");
    }
    
    push @{$self->items}, $item;

    return 1;
}

# Score
sub addScore {
    my ($self, $points) = @_;
    return $self->myScore($self->myScore + $points);
}

# Verbs
has verbs => (is => 'ro', default => sub { {score => 1, inventory => 1, drop => 1,} });
sub permits {
    my ($self, $verb) = @_;
    return unless $verb;

    return exists $self->verbs->{$verb};
}

sub score {
    return sprintf("Current score is %d.\n", shift->myScore);
}

sub inventory {
    my ($self) = @_;

    my $scene = join(", ", map { uc $_->name} @{ $self->items });
    
    return "$scene\n";
}

sub drop {
    my ($self, $item) = @_;

    if (!$item) {
        die("Drop what?\n");
    }

    my $itemName = (ref $item ? $item->name : $item);
    my $object = $self->hasItem($item);
    if (!$object) {
        die("You do not have $itemName\n");
    }

    $self->removeItem($object);

    return sprintf("You have dropped %s\n", $object->name);
}

1;
