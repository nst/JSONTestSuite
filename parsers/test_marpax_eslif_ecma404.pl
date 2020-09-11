#!/usr/bin/perl

use MarpaX::ESLIF::ECMA404;
use warnings;

my $path = $ARGV[0];

open( my $fh, '<', $path ) or die "Can't open $path: $!";

my $output;

# no decode_json as we need allow_nonref for RFC 7159
my $json = MarpaX::ESLIF::ECMA404->new;

my $data = do { local $/; <$fh> };

# MarpaX::ESLIF::ECMA404 is NOT a charset detector although it
# can detect quite reliably charset automatically. when the user
# KNOWS the charset, it is highly recommended to explicitely give
# it.
my $encoding;
if ($path =~ /utf\-?16be/i) {
    $encoding = 'UTF-16BE';
} elsif ($path =~ /utf\-?16le/i) {
    $encoding = 'UTF-16LE';
} elsif ($path =~ /utf\-?8/i) {
    $encoding = 'UTF-8';
} elsif (! ($path =~ /bom/i)) {
    #
    # Just to please OLD versions of perl, 5.10 for example.
    # In general this is not needed.
    #
    $encoding = 'UTF-8';
}
eval {
    $output = $json->decode ($data, $encoding);
};

my $jsonWasDecoded = defined($output);

if ($jsonWasDecoded) {
    exit 0;
}

exit 1;
