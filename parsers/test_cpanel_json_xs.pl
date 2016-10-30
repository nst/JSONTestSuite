#!/usr/bin/perl

use Cpanel::JSON::XS;
use warnings;

my $path = $ARGV[0];

open( my $fh, '<', $path ) or die "Can't open $path: $!";

my $output;

my $data = do { local $/; <$fh> };
eval {
    # RFC 7159: optional 2nd allow_nonref arg
    $output = decode_json $data, 1;
};
# $EVAL_ERROR ($@) is set to "" (false) if no error was detected
my $jsonWasDecoded = ! $@;

if ($jsonWasDecoded) {
    exit 0;
}

exit 1;
