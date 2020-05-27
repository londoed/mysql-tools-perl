#!/usr/bin/env perl

use strict;
use warnings;

use Carp;
use File::Basemap;
use Getopt::Long;

GetOptions(
    'k=i' => \(my $k = 5),
    'name=s' => \(my $name = ''),
    'suffix=s' => \(my $suffix = ''),
    'target-dir=s' => \(my $target_dir = ''),
) or die "[!] ERROR: Issue parsing command line arguments";

my $filename;
my $path = '';

if ($name eq '') {
    if (scalar @ARGV > 0) {
        ($filename, $path, $suffix) = fileparse($ARGV[0], qr/\..+/);
        $name = $filename;
    } else {
        $name = 'split';
    }
}

my @target_handles = ();

foreach my $fold (1..$k) {
    my $filename = "$target_dir/$name.$fold$suffix";

    open my $FILEHANDLE, '>', $filename
        or die "[!] ERROR: Could not open file -- $filename for reading";

    push @target_handles, $FILEHANDLE;
}

my $line_num = 0;

while (<>) {
    my $line = $_;

    my $CURRENT_HANDLE = $target_handles[$line_num % $k];
    print $CURRENT_HANDLE $line;
    $line_num++;
}

exit 0;
