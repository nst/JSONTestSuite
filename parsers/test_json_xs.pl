#!/usr/bin/perl
use strict;
use warnings;
use JSON::XS qw();

my $path = $ARGV[0];
open my $fh, '<', $path or die "Can't open $path: $!";

# no decode_json as we need allow_nonref for RFC 7159
my $json = JSON::XS->new->utf8->allow_nonref; # RFC 7159
eval {
    my $output = $json->decode(do { local $/; <$fh> });
    1;
} or exit 1;
exit 0;
