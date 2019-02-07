package item;
use strict;
use warnings;

use Moo;

has 'name' => (is => 'ro', required => 1);
has 'description' => (is => 'rw', default => sub { "This thing looks pretty much like you would imagine.\n" } );
has 'triggersGameOver' => (is => 'ro', default => sub { 0 });
has 'gameOverText' => (is => 'rw', default => sub { "You got me!\n" });
has 'points' => (is => 'rw', default => sub { 0 });
has verbs => (is => 'ro', default => sub { {examine => 1} });

sub permits {
    my ($self, $verb) = @_;
    return unless $verb;

    return exists $self->verbs->{$verb};
}

sub examine {
    shift->description;
}

1;
