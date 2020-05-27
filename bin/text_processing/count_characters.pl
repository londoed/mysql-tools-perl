#!/usr/bin/env perl

use strict;
use warnings;

my $character = shift;

if (! defined $character) {
    die "[!] ERROR: Please give a single character as the first parameter...\n";
}

if (length $character != 1) {
    die "[!] ERROR: Parameter '$character' is not a single character\n";
}

my $line_counter = 0;
my $character_count = 0;

LINE:
while (<>) {
    my $line = $_;
    $line_counter++;
    my $characters_in_line;

    eval "$characters_in_line = ($line " . " =~ tr/$character//";

    if ($@) {
        print "Fehler: $@";
    } else {
        $character_count += $characters_in_line;
    }
}

print "$line_counter lines, $character_count occurances of '$character'\n";
