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


ok(1);

done_testing;
