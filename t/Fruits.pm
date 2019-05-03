package Fruits;

use strict;
use warnings FATAL => 'all';

use parent qw/MouseX::Types::Enum/;
use Mouse;

has color => (is => 'ro', isa => 'Str');
has price => (is => 'ro', isa => 'Num');
has has_seed => (is => 'ro', isa => 'Int', default => 1);

sub make_sentence {
    my ($self, $suffix) = @_;
    $suffix ||= "";
    return sprintf("%s is %s%s", $self->name, $self->color, $suffix);
}

sub APPLE {1,
    color => 'red',
    price => 1,
}
sub GRAPE {2,
    color => 'purple',
    price => 2,
}
sub BANANA {3,
    color    => 'yellow',
    has_seed => 0,
    price    => 1.5,
}

__PACKAGE__->meta->make_immutable;

1;