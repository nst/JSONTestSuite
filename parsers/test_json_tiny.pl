#!/usr/bin/perl
use strict;
use warnings;
use JSON::Tiny qw(decode_json);

my $path = $ARGV[0];
open my $fh, '<', $path or die "Can't open $path: $!";
eval {
    my $output = decode_json do { local $/; <$fh> };
    1;
} or exit 1;
exit 0;
