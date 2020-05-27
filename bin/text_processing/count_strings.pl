#!/usr/bin/env perl

use strict;
use warnings;

my $string = shift;

if (! defined $string) {
    die "[!] ERROR: Please provide a string as the first parameter...\n";
}

my $line_counter = 0;
my $occurrence_counter = 0;

LINE:
while (<>) {
    my $line = $_;
    $line_counter++;

    while ($line =~ s/$string//) {
        $occurrence_counter++;
    }
}

print "$line_counter lines, $occurrence_counter occurrences of '$string'\n";
