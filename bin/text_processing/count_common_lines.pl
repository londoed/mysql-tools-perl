#/usr/bin/env perl

use strict;
use warnings;

use File::Slurp;

my $newline = "\n";

if ($ARGV[0] eq '-n') {
    $newline = '';
    shift @ARGV;
}

my @line_hashes = ();

foreach my $filename (@ARGV) {
    my @lines = read_file($filename);
    my %line_hash = map { $_ => 1 } @lines;
    push @line_hashes, \%line_hash;
}

my $common_counter = 0;
my $line_hash_one_ref = pop @line_hashes;

foreach my $line (keys %$line_hash_one_ref) {
    my $occurance_count = 0;

    foreach my $line_hash_ref (@line_hashes) {
        if (exists $line_hash_ref->{$line}) {
            $occurance_count++;
        }
    }

    if ($occurance_count == scalar @line_hashes) {
        $common_counter++;
    }
}

print "\n$common_counter\n";
