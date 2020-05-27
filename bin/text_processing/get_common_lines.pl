#!/usr/bin/env perl

use strict;
use warnings;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use File::Slurp;
use Getopt::Long;

my $file1 = shift;
my $file2 = shift;

my @lines1 = read_file($file1);
my %lines1 = ();

foreach my $line (@lines1) {
    $lines1{$line} = 1;
}

my @lines2 = read_file($file2);

foreach my $line (@lines2) {
    if (exists $lines1{$line}) {
        print $line;
    }
}
