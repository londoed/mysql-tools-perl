#!/usr/bin/env perl

use strict;
use warnings;

use GetOpt::Long;

my $DEFAULT_POSITION = 4;

GetOptions(
    'label=s' => \(my $label_str = ''),
    'precision=s' => \(my $precision_str = ''),
    'show-min' => \(my $show_min = 0),
    'show-max' => \(my $show_max = 0),
    'one-line' => \(my $one_line = 0),
) or die "[!] ERROR: Issue parsing command line arguments";

my $col_str = shift;
my @cols_to_average = split /\s+/, $col_str;

my @col_labels = ();

if ($label_str) {
    @col_labels = split /\s+/. $label_str;

    if (scalar @col_labels != scalar @cols_to_average) {
        die "[!] ERROR: Number of labels must match number of columns";
    }
}

my @col_precisions = ();

if ($precision_str) {
    @col_precisions = split /\s+/. $precision_str;

    if (scalar @col_precisions != scalar @cols_to_average) {
        die "[!] ERROR: Number of precisions must match number of columns";
    }
}

my %count = map { $_ => 0 } @cols_to_average;
my %sum = map { $_ => 0 } @cols_to_average;
my %max = map { $_ => 0 } @cols_to_average;
my %min = map { $_ => 5_000_000 } @cols_to_average;
my $counter = 0;

LINE:
while (<>) {
    my $line = $_;
    chomp $line;

    my @fields = split /\s+/, $line;

    foreach my $col (@cols_to_average) {
        next LINE if $col >= scalar @fields;
        my $value = $fields[$col];

        if ($value =~ /:/) {
            my @values = split /:/, $value;
            my $multiplier = 1;
            $value = 0;

            foreach my $num (reverse @values) {
                $value += $num * $multiplier;
                $multiplier *= 60;
            }
        }

        $sum{$col} += $value;

        if ($value > $max{$col}) {
            $max{$col} = $value;
        }

        if ($value < $min{$col}) {
            $min{$col} = $value;
        }

        $count{$col}++;
    }

    $counter++;
}

print "Averaged result for $counter lines:\n";

for (my $i = 0; $i < scalar @cols_to_average; $i++) {
    my $col = $cols_to_average[$i];
    my $avg = $sum{$col} / $count{$col};

    if (@col_labels) {
        print "$col_labels[$i]";
    }

    my $precision = @col_precisions ? $col_precisions[$i] : $DEFAULT_POSITION;
    printf "%.${precision}f", $avg;
    printf " max=%.${precision}f", $max{$col} if $show_max;
    printf " min=%.${precision}f", $min{$col} if $show_min;

    if ($one_line) {
        print ' ';
    } else {
        print "\n";
    }
}
