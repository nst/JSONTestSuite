#!/usr/bin/perl

use JSON;
use warnings;

my $path = $ARGV[0];

open( my $fh, '<', $path ) or die "Can't open $path: $!";

my $output;

# no decode_json as we need allow_nonref for RFC 7159
my $json = JSON->new->utf8->allow_nonref; # RFC 7159

my $data = do { local $/; <$fh> };
eval {
    $output = $json->decode ($data);
};
# $EVAL_ERROR ($@) is set to "" (false) if no error was detected
my $jsonWasDecoded = ! $@;

if ($jsonWasDecoded) {
    exit 0;
}

exit 1;
