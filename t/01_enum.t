use strict;
use warnings FATAL => 'all';
use Test::More 0.98;
use Scalar::Util qw/refaddr/;
use Test::Exception;

BEGIN {
    use File::Basename qw/dirname/;
    my $dir = dirname(__FILE__);
    push(@INC, $dir);
}

use Fruits;

subtest 'Correct enum objects are generated' => sub {
    ok(Fruits::APPLE);
    ok(Fruits::GRAPE);
    ok(Fruits::BANANA);

    ok(Fruits->APPLE);
    ok(Fruits->GRAPE);
    ok(Fruits->BANANA);
};

subtest 'Each objects are singleton' => sub {
    ok(refaddr(Fruits->APPLE) eq refaddr(Fruits->APPLE));
    ok(refaddr(Fruits->GRAPE) eq refaddr(Fruits->GRAPE));
    ok(refaddr(Fruits->BANANA) eq refaddr(Fruits->BANANA));
};

subtest 'Operator `==` works correctly' => sub {
    ok(Fruits->APPLE == Fruits->APPLE);
    ok(Fruits->GRAPE == Fruits->GRAPE);
    ok(Fruits->BANANA == Fruits->BANANA);

    ok(!(Fruits->APPLE == Fruits->GRAPE));
    ok(!(Fruits->GRAPE == Fruits->APPLE));
    ok(!(Fruits->APPLE == Fruits->BANANA));
    ok(!(Fruits->BANANA == Fruits->APPLE));
    ok(!(Fruits->GRAPE == Fruits->BANANA));
    ok(!(Fruits->BANANA == Fruits->GRAPE));

    ok(!(Fruits->APPLE == 123));
    ok(!(123 == Fruits->APPLE));
    ok(!(Fruits->APPLE == 'foo'));
    ok(!('foo' == Fruits->APPLE));
};

subtest 'Operator `!=` works correctly' => sub {
    ok(!(Fruits->APPLE != Fruits->APPLE));
    ok(!(Fruits->GRAPE != Fruits->GRAPE));
    ok(!(Fruits->BANANA != Fruits->BANANA));

    ok(Fruits->APPLE != Fruits->GRAPE);
    ok(Fruits->GRAPE != Fruits->APPLE);
    ok(Fruits->APPLE != Fruits->BANANA);
    ok(Fruits->BANANA != Fruits->APPLE);
    ok(Fruits->GRAPE != Fruits->BANANA);
    ok(Fruits->BANANA != Fruits->GRAPE);

    ok(Fruits->APPLE != 1);
    ok(1 != Fruits->APPLE);
    ok(Fruits->APPLE != 123);
    ok(123 != Fruits->APPLE);
    ok(Fruits->APPLE != 'foo');
    ok('foo' != Fruits->APPLE);
};

subtest 'Operator `eq` works correctly' => sub {
    ok(Fruits->APPLE eq Fruits->APPLE);
    ok(Fruits->GRAPE eq Fruits->GRAPE);
    ok(Fruits->BANANA eq Fruits->BANANA);

    ok(!(Fruits->APPLE eq Fruits->GRAPE));
    ok(!(Fruits->GRAPE eq Fruits->APPLE));
    ok(!(Fruits->APPLE eq Fruits->BANANA));
    ok(!(Fruits->BANANA eq Fruits->APPLE));
    ok(!(Fruits->GRAPE eq Fruits->BANANA));
    ok(!(Fruits->BANANA eq Fruits->GRAPE));

    ok(!(Fruits->APPLE eq 1));
    ok(!(1 eq Fruits->APPLE));
    ok(!(Fruits->APPLE eq 123));
    ok(!(123 eq Fruits->APPLE));
    ok(!(Fruits->APPLE eq 'foo'));
    ok(!('foo' eq Fruits->APPLE));
};

subtest 'Operator `ne` works correctly' => sub {
    ok(!(Fruits->APPLE ne Fruits->APPLE));
    ok(!(Fruits->GRAPE ne Fruits->GRAPE));
    ok(!(Fruits->BANANA ne Fruits->BANANA));

    ok(Fruits->APPLE ne Fruits->GRAPE);
    ok(Fruits->GRAPE ne Fruits->APPLE);
    ok(Fruits->APPLE ne Fruits->BANANA);
    ok(Fruits->BANANA ne Fruits->APPLE);
    ok(Fruits->GRAPE ne Fruits->BANANA);
    ok(Fruits->BANANA ne Fruits->GRAPE);

    ok(Fruits->APPLE ne 1);
    ok(1 ne Fruits->APPLE);
    ok(Fruits->APPLE ne 123);
    ok(123 ne Fruits->APPLE);
    ok(Fruits->APPLE ne 'foo');
    ok('foo' ne Fruits->APPLE);
};

subtest 'Cannot use other binary operators' => sub {
    throws_ok {Fruits->APPLE > Fruits->GRAPE;} qr//;
    throws_ok {Fruits->APPLE >= Fruits->GRAPE;} qr//;
    throws_ok {Fruits->APPLE < Fruits->GRAPE;} qr//;
    throws_ok {Fruits->APPLE <= Fruits->GRAPE;} qr//;
    throws_ok {Fruits->APPLE + Fruits->GRAPE;} qr//;
    throws_ok {Fruits->APPLE + Fruits->GRAPE;} qr//;
};

subtest 'Converted to string correctly' => sub {
    is("" . Fruits->APPLE, "APPLE");
    is(Fruits->APPLE . "", "APPLE");
    is("" . Day->Sun, "Sun");
    is(Day->Sun . "", "Sun");

    is(Fruits->BANANA->to_string, "BANANA");
    is(Day->Mon->to_string, "Mon");
};

subtest 'Call instance method' => sub {
    is(Fruits->APPLE->make_sentence, "Apple is red");
    is(Fruits->GRAPE->make_sentence, "Orange is orange");
    is(Fruits->BANANA->make_sentence('!!!'), "Banana is yellow!!!");
};

subtest 'Correct values is set' => sub {
    is(Fruits->APPLE->name, 'Apple');
    is(Fruits->GRAPE->name, 'Orange');
    is(Fruits->BANANA->name, 'Banana');
    is(Fruits->APPLE->color, 'red');
    is(Fruits->GRAPE->color, 'orange');
    is(Fruits->BANANA->color, 'yellow');
    is(Fruits->APPLE->has_seed, 1);
    is(Fruits->GRAPE->has_seed, 1);
    is(Fruits->BANANA->has_seed, 0);
};

subtest 'Lazy loading' => sub {
    {
        package Foo;
        use MouseX::Types::Enum (
            'A',
            'B',
            'C'
        );
    }

    is((scalar grep {$_} values %{Foo->_instances}), 0);
    is(Foo->_instances->{A}, undef);
    Foo->A;
    is((scalar grep {$_} values %{Foo->_instances}), 1);
    is(Foo->_instances->{A}, Foo->A);

    my $enums = Foo->enums;
    is_deeply($enums, {
        A => Foo->A,
        B => Foo->B,
        C => Foo->C,
    });
};

subtest 'Get all enums' => sub {
    is_deeply(
        Fruits->all,
        {
            APPLE  => Fruits->APPLE,
            GRAPE => Fruits->GRAPE,
            BANANA => Fruits->BANANA
        }
    );
    is_deeply(
        Day->enums,
        {
            Sun => Day->Sun,
            Mon => Day->Mon,
            Tue => Day->Tue,
            Wed => Day->Wed,
            Thu => Day->Thu,
            Fri => Day->Fri,
            Sat => Day->Sat
        }
    );
};

subtest 'Subroutine scopes' => sub {
    subtest 'Has private constructor' => sub {
        throws_ok {
            Fruits->new({
                GRAPE => { name => 'Grape', color => 'Purple' }
            })
        } qr/Can't instantiate/;
    };

    subtest 'Each enum objects cannot call itself' => sub {
        throws_ok {
            Fruits->APPLE->APPLE
        } qr/`APPLE` can only be called/;
    };

    subtest "Can't invoke class method from instances" => sub {
        throws_ok {
            Fruits->APPLE->enums
        } qr/is class method/;
    };
};

subtest 'Reserved words' => sub {
    subtest 'Attribute name `_id` is reserved' => sub {
        throws_ok {
            {
                package Hoge;

                # Pseudo use package
                require MouseX::Types::Enum;
                MouseX::Types::Enum->import(
                    Foo => { _id => 'foo' }
                );
            }
        } qr/`Hoge::_id` is reserved./;
    };

    subtest 'Cannot declare reserved word as key' => sub {
        for (qw/_equals _not_equals enums to_string _instances/) {
            throws_ok {
                {
                    package Buzz;

                    # Pseudo use package
                    require MouseX::Types::Enum;
                    MouseX::Types::Enum->import(
                        $_ => {},
                    );
                }
            } qr/`Buzz::$_` is already defined or reserved/, '';

        }
    };
};

done_testing;
