#!/usr/bin/perl

#use strict;
use warnings;
use JSON;

my $path = $ARGV[0];

open( my $fh, '<', $path ) or die "Can't open $path: $!";

my $jsonWasDecoded = 0;

my $text = "";

my $data = do { local $/; <$fh> };
eval {
    $text = from_json( $data, { allow_nonref => 1, utf8 => 1, relaxed => 1 } );
    #$text = JSON->new->utf8->allow_nonref->decode($data); # TODO: should use decode_json
};
$jsonWasDecoded = $text ne "";

close $fh;

if ($jsonWasDecoded) {
    exit 0;
}

exit 1;
