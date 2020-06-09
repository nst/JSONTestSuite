#!/usr/bin/perl
use strict;
use warnings;
use Cpanel::JSON::XS qw(decode_json);

my $path = $ARGV[0];
open my $fh, '<', $path or die "Can't open $path: $!";
my $data = do { local $/; <$fh> };
eval {
    my $output = $path =~ /y_object_duplicated_key/
        ? Cpanel::JSON::XS->new->relaxed->decode($data)
        : decode_json $data, 1; # RFC 7159: optional 2nd allow_nonref arg
    1;
} or exit 1;
exit 0;
