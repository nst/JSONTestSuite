#!/usr/bin/perl
use strict;
use warnings;
use Pegex::JSON qw();

my $path = $ARGV[0];
open my $fh, '<', $path or die "Can't open $path: $!";
eval {
    my $output = Pegex::JSON->new->load(do { local $/; <$fh> });
    1;
} or exit 1;
exit 0;
