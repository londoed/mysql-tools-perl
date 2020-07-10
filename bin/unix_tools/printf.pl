#!/usr/bin/env perl

use strict;
use warnings;

END {
    close STDOUT || die "[!] ERROR: $0 can't close stdout -- $!\n";
    $? = 1 if $? == 255;
}

unless (@ARGV) {
    die "[!] USAGE: $0 format [argument ...]\n";
}

my $format = shift;
eval qq<printf "$format", \@ARGV>;
die if $@;

__END__
