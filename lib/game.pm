package game;
use strict;
use warnings;

use Text::Wrap;

use dude;
use location;

use Moo;
our $Game;

has dude => (is => 'ro', lazy => 1, builder => 1);
sub _build_dude {
    return dude->new;
}

has locations => (is => 'ro', lazy => 1, builder => 1);
sub _build_locations {
    my ($self) = @_;
    
    return [ ];
}

has gameOver => (is => 'rw', default => sub { 0 });
has introduction => (is => 'rw', lazy => 1, builder => 1);

sub _build_introduction {
    return "You are in a large mansion with many rooms.\n";
}

sub BUILD {
    my ($self) = @_;

    if (!$self->hasLocations) {
        $self->addLocation(location->new(name => "start", game => $self));
    }
}

# This is a singleton
sub get_instance {
    if (!$Game) {
        $Game = __PACKAGE__->new;
    }

    return $Game;
}

sub hasLocation {
    my ($self, $location) = @_;
    return unless $location;
    return grep { $_->name eq $location->name } @{$self->locations};
}

sub hasLocations {
    my ($self) = @_;
    return @{$self->locations} > 0;
}

sub firstLocation {
    my ($self) = @_;
    return $self->locations->[0];
}

sub addLocation {
    my ($self, $location) = @_;
    if ($self->hasLocation($location)) {
        return;
    }

    push @{$self->locations}, $location;

    # dude's gotta be somewhere
    if (!$self->dude->location) {
        $self->dude->location($location);
    }

    return 1;
}

sub removeLocation {
    my ($self, $location) = @_;

    my @tmp;
    for my $l (@{$self->locations}) {
        if ($location->name eq $l->name) {
            next;
        }
        push @tmp, $l;
    }

    @{ $self->locations } = @tmp;
    
    return 1;
}

sub run {
    my ($self) = @_;
    $|++;

    $self->response($self->introduction);
    
    while (!$self->gameOver) {
        $self->response($self->prompt());
        my $response;
        my $rc =  eval {
            $response = $self->getInput();
        };
        
        if ($rc) {
            $self->response($response || "OK");
            if ($self->gameOver) {
                $self->response($self->quit);
            }
        } else {
            $self->response($@);
        }
    }        
}

sub prompt {
    my ($self) = @_;
    return "> ";
}

sub getInput {
    my ($self) = @_;

    my $line = readline();
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;

    my $thisLocation = $self->dude->location;
    if (!$thisLocation) {
        $thisLocation = $self->dude->location;
    }

    # Allowed productions
    # VERB
    # VERB DIRECTION
    # VERB ITEM
    my @words = split /\s+/, $line;
    my $action = shift @words;

    my ($locationItem, $inventoryItem);
    if (@words) {
        ($locationItem, $inventoryItem) = ($thisLocation->hasItem(join(" ", @words)),
                                           $self->dude->hasItem(join(" ", @words))
            );
    }

    if ($thisLocation->permits( $action )) {
        return $thisLocation->$action( $locationItem || lc $words[0] ); # thing or direction 
    }

    # Is this a thing verb?
    # Convert @words[1,-1] into a thing
    if ($locationItem && $locationItem->permits( $action )) {
        return $locationItem->$action();
    }
    
    # Can the dude do this?
    if ($self->dude->permits($action)) {
        return $self->dude->$action($inventoryItem);
    }

    # Can game do this?
    if ($self->permits($action)) {
        return $self->$action();
    }

    return;
}

sub response {
    my ($self, $msg) = @_;
    print wrap("", "", $msg);
}

has verbs => (is => 'ro', default => sub { { quit => 1, help => 1 }});

sub permits {
    my ($self, $verb) = @_;
    return unless $verb;

    return exists $self->verbs->{$verb};
}

sub quit {
    my ($self) = @_;

    $self->gameOver(1);
    return sprintf("Game over.  Your final score was %d\n", $self->dude->myScore);
}


sub help {
    my ($self) = @_;
    my $thisLocation = $self->firstLocation;
    my $dude = $self->dude;

    my @verbs = (keys %{ $thisLocation->verbs }, keys %{ $dude->verbs }, keys %{ $self->verbs });
    if ($thisLocation->hasItems) {
        push @verbs, keys %{ $thisLocation->items->[0]->verbs }
    }

    return sprintf("Available commands are: %s\n", join(", ", sort @verbs));
}

1;
