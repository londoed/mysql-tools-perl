#!/usr/bin/env perl

use strict;
use warnings;

use English qw{-no_match_vars};
use File::Slurp;
use Getopt::Long;

GetOptions(
    'help' => \(my $help = 0),
    'ignore-lines=i' => \(my $ignore_lines = 0),
    'rest-separators=s' => \(my $rest_separator = ' '),
) or usage(-1);

usage(0) if $help;

my $mapping_file = shift;
my @lines = read_file($mapping_file);

my %mapping = ();

foreach my $line (@lines) {
    chomp $line;

    my @fields = split /\s+/, $line;

    if (scalar @fields != 2) {
        die "[!] ERROR: Couldn't read line -- '$line'\n";
    }

    my ($key, $value) = @fields;
    $mapping{$key} = $value;
}

for (my $i = 0; $i < $ignore_lines; $i++) {
    <>;
}

LINE:
while (<>) {
    my $line = $_;
    chomp $line;

    my @fields = split /\s+/, $line;
    my ($first_col, @rest) = @fields;
    my $rest = join $rest_separator, @rest;
    print "$mapping{$first_col}${$rest_separator}${rest}\n";
}

sub usage {
    my ($return_code) = shift;

    print << "END";
    $PROGRAM_NAME.

    usage: $PROGRAM_NAME MAPPING_FILE [OPTIONS]

    --help                  display this usage information
    --ignore-lines=N
    --rest-separator=SEP
END
    exit $return_code;
}
