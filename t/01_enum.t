use strict;
use warnings;
use Test::More 0.98;
use Scalar::Util qw/refaddr/;
use Test::Exception;

BEGIN {
    use File::Basename qw/dirname/;
    my $dir = dirname(__FILE__);
    push(@INC, $dir);
}

use Fruits;

{
    package Bar;
    use parent qw/MouseX::Types::Enum/;
    __PACKAGE__->_build_enum;
}

subtest 'Correct enum objects are generated' => sub {
    ok(Fruits->APPLE);
    ok(Fruits->GRAPE);
    ok(Fruits->BANANA);

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
    throws_ok {Fruits->APPLE > Fruits->GRAPE;} qr/.+/;
    throws_ok {Fruits->APPLE >= Fruits->GRAPE;} qr/.+/;
    throws_ok {Fruits->APPLE < Fruits->GRAPE;} qr/.+/;
    throws_ok {Fruits->APPLE <= Fruits->GRAPE;} qr/.+/;
    throws_ok {Fruits->APPLE + Fruits->GRAPE;} qr/.+/;
    throws_ok {Fruits->APPLE + Fruits->GRAPE;} qr/.+/;
};

subtest 'Converted to string correctly' => sub {
    is("" . Fruits->APPLE, "Fruits[id=1]");
    is(Fruits->APPLE . "", "Fruits[id=1]");
};

subtest 'Call instance method' => sub {
    is(Fruits->APPLE->make_sentence, "Apple is red");
    is(Fruits->GRAPE->make_sentence, "Grape is purple");
    is(Fruits->BANANA->make_sentence('!!!'), "Banana is yellow!!!");
};

subtest 'Correct values is set' => sub {
    is(Fruits->APPLE->name, 'Apple');
    is(Fruits->GRAPE->name, 'Grape');
    is(Fruits->BANANA->name, 'Banana');
    is(Fruits->APPLE->color, 'red');
    is(Fruits->GRAPE->color, 'purple');
    is(Fruits->BANANA->color, 'yellow');
    is(Fruits->APPLE->has_seed, 1);
    is(Fruits->GRAPE->has_seed, 1);
    is(Fruits->BANANA->has_seed, 0);
};

subtest 'Get specific enum' => sub {
    is(Fruits->get(2), Fruits->GRAPE);
};

subtest 'Get all enums' => sub {
    is_deeply(
        Fruits->all,
        {
            1 => Fruits->APPLE,
            2 => Fruits->GRAPE,
            3 => Fruits->BANANA
        }
    );
};

subtest 'Lazy loading' => sub {
    {
        package Foo;
        use parent qw/MouseX::Types::Enum/;

        sub A {1}
        sub B {2}
        sub C {3}

        __PACKAGE__->_build_enum;
    }

    is(Foo->_enums->{1}, undef);
    Foo->A;
    is(Foo->_enums->{1}, Foo->A);

    my $enums = Foo->all;
    is_deeply($enums, {
        1 => Foo->A,
        2 => Foo->B,
        3 => Foo->C,
    });
};

subtest 'Subroutine scopes' => sub {
    subtest 'Base class is abstract' => sub {
        throws_ok {
            MouseX::Types::Enum->new;
        } qr/is abstract/;
    };

    subtest 'Each enum objects cannot call itself' => sub {
        throws_ok {
            Fruits->APPLE->APPLE;
        } qr/APPLE.* can only be called/;
    };

    subtest 'Cannot instanciate' => sub {
        throws_ok {
            Fruits->new;
        } qr/.+/;
    };

    subtest "Can't invoke class method from instances" => sub {
        throws_ok {
            Fruits->APPLE->all;
        } qr/is class method/;
        throws_ok {
            Fruits->APPLE->get(0);
        } qr/is class method/;
    };
};

subtest 'Reserved words' => sub {
    for my $sub (qw/_id _enums all get _to_string _equals/) {
        subtest "Attribute name `$sub` is reserved" => sub {
            eval <<"PERL5";
{
    package Hoge_$sub;
    use parent qw/MouseX::Types::Enum/;

    sub $sub {}

    __PACKAGE__->_build_enum;
}
PERL5
            my $err = $@;
            ok($err =~ /$sub.+is reserved/);
        };
    }
};

subtest 'id duplication' => sub {
    eval <<"PERL5";
{
    package DupId;
    use parent qw/MouseX::Types::Enum/;

    sub AAA {1}
    sub BBB {1}

    __PACKAGE__->_build_enum;
}
PERL5
    my $err = $@;
    ok($err =~ /.+/);
};

subtest 'enum name' => sub {
    {
        package Hoge;
        use parent qw/MouseX::Types::Enum/;

        sub AAA {1}
        sub _AAA {2}
        sub AAA_ {3}
        sub AAA_123 {4}
        sub aaa {5}
        sub _aaa {6}

        __PACKAGE__->_build_enum;
    }
    is_deeply(Hoge->all, {
        1 => Hoge->AAA,
        2 => Hoge->_AAA,
        3 => Hoge->AAA_,
        4 => Hoge->AAA_123,
    })
};

done_testing;
