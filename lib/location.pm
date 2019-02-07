package location;
use strict;
use warnings;

use Moo;

has 'description' => (is => 'rw', default => sub { "This room is much like the others.\n" } );
has 'exits' => (is => 'rw', default => sub { {} });
has 'name' => (is => 'ro', required => 1);
has 'points' => (is => 'rw', default => sub { 1 });
has 'requiredItems' => (is => 'rw', default => sub { [] });
has 'triggersGameOver' => (is => 'ro', default => sub { 0 });
has 'gameOverText' => (is => 'rw', default => sub { "You found the exit!\n" });
has 'visited' => (is => 'rw', default => sub { 0 });

has 'game' => (is => 'ro', lazy=>1, builder=>1);
sub _build_game {
    my ($self) = @_; 
    my $game = game->get_instance;
    if (!$game->hasLocations) {
        $game->addLocation($self);
    }
    return $game;
}

sub BUILD {
    my ($self, $args) = @_;

    if (!$self->game->hasLocation($self)) {
        $self->game->addLocation($self);
    }
}

has 'items' => (is => 'rw', default => sub { [] });

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
    $item = $self->hasItem($item);
    
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

our %LOCATIONS = ('north'=>1, 'south'=>1, 'east'=>1, 'west'=>1);

sub other_direction {
    my ($self, $direction) = @_;

    return 'south' if $direction eq 'north';
    return 'north' if $direction eq 'south';
    return 'east' if $direction eq 'west';
    return 'west' if $direction eq 'east';

    die("assert");
}

sub hasExits {
    return keys %{shift->exits} > 0;
}

sub addExit {
    my ($self, $direction, $location) = (shift, shift, shift);;

    my %opts = (
        addBackLinks => 1,
        requireItems => [],
        @_);

    if (!exists $LOCATIONS{$direction}) {
        die("No such location '$direction'\n");
    }

    if (!$location) {
        die("No location given\n");
    }

    if (defined $self->exits->{$direction}) {
        die("This location already has an exit to the '$location'\n");
    }

    $self->exits->{$direction} = $location;
    for my $item (@{$opts{requiredItems}}) {
        push @{$location->requiredItems}, $item;
    }
    
    if ($opts{addBackLinks}) {
        # Get the opposite direction
        my $reverse = $self->other_direction($direction);
        # Does this exist?
        if ($location->exits->{$reverse}) {
            if ($location->exits->{$reverse} != $self) {
                die("The other location already has an exit to the '$reverse'\n");
            }
            return 1;
        }

        my $method = sprintf("add%s", ucfirst $reverse);
        $location->$method($self);
    }

    return 1;
}

sub addNorth {
    my ($self, $location) = (shift, shift);
    return $self->addExit('north', $location, @_);
}

sub addSouth {
    my ($self, $location) = (shift, shift);
    return $self->addExit('south', $location);
}

sub addEast {
    my ($self, $location) = (shift, shift);
    return $self->addExit('east', $location);
}

sub addWest {
    my ($self, $location) = (shift, shift);
    return $self->addExit('west', $location);
}

# Object verbs go here
has verbs => (is => 'ro', default => sub { { look => 1, go => 1, take => 1 }});

sub permits {
    my ($self, $verb) = @_;
    return unless $verb;

    return exists $self->verbs->{$verb};
}

sub look {
    my ($self) = @_;
    my $scene = $self->description;
    if ($self->hasItems) {
        $scene .= sprintf("\nYou notice the following items here: %s.\n", join(", ", map { uc $_->name } @{$self->items}) );
    }

    if ($self->hasExits) {
        $scene .= sprintf("\nExits appear in the following directions: %s\n", join(", ", map { uc $_ } sort keys %{$self->exits} ));
    }

    return $scene;
}

sub go {
    my ($self, $direction) = @_;

    if (!$direction) {
        die("I know you want to go somewhere, but where?\n");
    }

    if (!exists $LOCATIONS{$direction})  {
        die "No exits found in direction '$direction'.\n";
    }

    if (!$self->exits->{$direction}) {
        die "No exits found in direction '$direction'.\n";
    }
    
    my $location = $self->exits->{$direction};
    for my $item (@{$self->requiredItems}) {
        if (!$self->game->dude->hasItem($item)) {
            die "You cannot go this way without a certain item in your inventory.\n";
        }
    }

    if (!$location->visited) {
        $self->game->dude->addScore($location->points);
    }

    $location->visited(1);
    $self->game->dude->location($location);
    
    if ($location->triggersGameOver) {
        $self->game->gameOver(1);
    }
        
    return $location->description; # caller will update PC location
}

sub take {
    my ($self, $item) = @_;

    if (!ref $item) {
        $item = uc $item;
    }

    if (!$self->hasItem($item)) {
        die(sprintf("There is no %s here.\n", (ref $item ? uc $item->name : $item)));
    }
    
    my $object = $self->hasItem($item);
    $self->removeItem($item);

    $self->game->dude->addItem($object);
    
    $self->game->dude->addScore($object->points);

    if ($object->triggersGameOver) {
        $self->game->gameOver(1);
        return $object->gameOverText;
    }
    
    return "You take " . $object->name . "\n";
}

1;
