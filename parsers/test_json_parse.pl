#!/usr/bin/perl
use strict;
use warnings;
use JSON::Parse qw(parse_json);

my $path = $ARGV[0];
open my $fh, '<:encoding(UTF-8)', $path or die "Can't open $path: $!";
eval {
    my $output = parse_json do { local $/; <$fh> };
    1;
} or exit 1;
exit 0;
