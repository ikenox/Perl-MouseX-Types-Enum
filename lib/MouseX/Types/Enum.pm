package MouseX::Types::Enum;
use 5.008001;

use strict;
use warnings;

our $VERSION = "2.00";

use Mouse;
use Carp qw/confess/;
use Class::Inspector;

has id => (is => 'ro', isa => 'Str');

around BUILDARGS => sub {
    my ($orig, $class, @params) = @_;

    # This package is abstract class
    confess __PACKAGE__ . " is abstract class." if $class eq __PACKAGE__;

    return $class->$orig(@params);
};

my @EXPORT_MOUSE_METHODS = qw/has with before after around/;
my %_ENUM_METAS;

# install Mouse methods to the child package
if (caller eq 'parent') {
    my $child = caller(1);

    #@type Mouse::Meta::Class
    my $meta = Mouse->init_meta(for_class => $child);

    no strict 'refs';
    no warnings 'redefine';
    for my $method (@EXPORT_MOUSE_METHODS) {
        $meta->add_method($method => \&{"Mouse::$method"});
    }

    $meta->add_around_method_modifier(BUILDARGS => sub {
        my ($orig, $class, @params) = @_;
        # disallow creating instance
        if (caller(2) ne __PACKAGE__) {
            confess sprintf("Cannot call $child->new outside of %s (called in %s)", __PACKAGE__, caller(2) . "")
        }
        return $class->$orig(@params);
    });
}

sub _build_enum {
    my ($child, %build_params) = @_;
    my $parent = __PACKAGE__;

    # this subroutine should be called as `__PACKAGE__->build_enum`.
    unless (caller() eq $child && !ref($child)) {
        confess "Please call as `__PACKAGE__->_build_enum`.";
    }

    # check reserved subroutine names
    my @child_subs = @{Class::Inspector->functions($child)};
    my @parent_subs = @{Class::Inspector->functions($parent)};
    my %reserved_subs = map {$_ => undef} @parent_subs;
    my %dup_allow_subs = map {$_ => undef} (@EXPORT_MOUSE_METHODS, 'meta', 'BUILDARGS');
    for my $sub_name (@child_subs) {
        if (exists $reserved_subs{$sub_name} && !exists $dup_allow_subs{$sub_name}) {
            confess "`$sub_name` is reserved by " . __PACKAGE__ . ".";
        }
    }

    {
        no strict 'refs';
        no warnings 'redefine';
        # Overwrite enums
        my @enum_subs = grep {$_ =~ /^[A-Z0-9_]+$/} @child_subs;
        my %ignored_subs = map {$_ => undef} ('BUILDARGS', @{$build_params{ignore}});
        for my $sub_name (@enum_subs) {
            next if exists $ignored_subs{$sub_name};
            my ($id, @args) = $child->$sub_name;
            confess "seems to be invalid argument." if scalar(@args) % 2;
            confess "unique id is required for $child->$sub_name ." unless $id;
            my %args = @args;

            if (exists $child->_enums->{$id}) {
                confess "id `$id` is duplicate."
            }
            $child->_enums->{$id} = undef;

            *{"${child}\::${sub_name}"} = sub {
                my $class = shift;
                if ($class && $class ne $child) {
                    confess "`${child}::$sub_name` can only be called as static method of `$child`. Please call `${child}->${sub_name}`.";
                }
                return $class->_enums->{$id} //= $class->new(
                    id => $id,
                    %args
                );
            }
        }
    }

    $child->meta->make_immutable;
}

use overload
    # MouseX::Types::Enum can only be applied following operators
    'eq' => \&_equals,
    'ne' => \&_not_equals,
    '==' => \&_equals,
    '!=' => \&_not_equals,
    '""' => \&_to_string,
;

sub get {
    my ($class, $id) = @_;
    confess "this is class method." if ref($class);
    return $class->_enums->{$id} // confess "$id is not found."
}

sub all {
    my ($class) = shift;
    confess "this is class method." if ref($class);
    return $class->_enums;
}

sub _to_string {
    my ($self) = @_;
    return sprintf("%s[id=%s]", ref($self), $self->id);
}

sub _equals {
    my ($first, $second) = @_;
    return (ref($first) eq ref($second)) && ($first->id eq $second->id);
}

sub _not_equals {
    my ($first, $second) = @_;
    return !_equals($first, $second);
}

sub _enum_meta {
    my ($class) = @_;
    return $_ENUM_METAS{$class} //= {};
}

sub _enums {
    my ($class) = @_;
    return $class->_enum_meta->{enums} //= {};
}

sub _overwrite_flg {
    my ($class) = @_;
    return $class->_enum_meta->{overwrite_flg} //= {};
}


1;
__END__

=encoding utf-8

=head1 NAME

MouseX::Types::Enum - Object-oriented, Java-like enum type declaration based on Mouse

=head1 SYNOPSIS

In the following example,

=over 4

=item *

Three enumeration constants, C<< APPLE >>, C<< ORANGE >>, and C<< BANANA >> are defined.

=item *

Three instance variables, C<< name >>, C<< color >>, and C<< has_seed >> are defined.

=item *

A method C<< make_sentence($suffix) >> is defined.

=back

code:


    {
        package Fruits;

        use Mouse;
        use MouseX::Types::Enum (
            APPLE  => { name => 'Apple', color => 'red' },
            ORANGE => { name => 'Orange', color => 'orange' },
            BANANA => { name => 'Banana', color => 'yellow', has_seed => 0 }
        );

        has name => (is => 'ro', isa => 'Str');
        has color => (is => 'ro', isa => 'Str');
        has has_seed => (is => 'ro', isa => 'Int', default => 1);

        sub make_sentence {
            my ($self, $suffix) = @_;
            $suffix ||= "";
            return sprintf("%s is %s%s", $self->name, $self->color, $suffix);
        }

        __PACKAGE__->meta->make_immutable;
    }

    Fruits->APPLE == Fruits->APPLE;        # 1
    Fruits->APPLE == Fruits->ORANGE;       # ''
    Fruits->APPLE->to_string;              # 'APPLE'

    Fruits->APPLE->name;                   # 'Apple';
    Fruits->APPLE->color;                  # 'red'
    Fruits->APPLE->has_seed;               # 1

    Fruits->APPLE->make_sentence('!!!');   # 'Apple is red!!!'

    Fruits->enums; # { APPLE  => Fruits->APPLE, ORANGE => Fruits->ORANGE, BANANA => Fruits->BANANA }

If you have no need to define instance variables, you can declare enums more simply like following.

    {
        package Day;

        use MouseX::Types::Enum qw/
            Sun
            Mon
            Tue
            Wed
            Thu
            Fri
            Sat
        /;

        __PACKAGE__->meta->make_immutable;
    }

    Day->Sun == Day->Sun;   # 1
    Day->Sun == Day->Mon;   # ''
    Day->Sun->to_string;    # 'Sun'
    Day->enums;             # { Sun => Day->Sun, Mon => Day->Mon, ... }


=head1 DESCRIPTION

MouseX::Types::Enum provides Java-like enum type declaration based on Mouse.
You can declare enums which have instance variables and methods.

=head1 LICENSE

Copyright (C) Naoto Ikeno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Naoto Ikeno E<lt>ikenox@gmail.comE<gt>

=cut

