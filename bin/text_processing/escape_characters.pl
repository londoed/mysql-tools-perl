#!/usr/bin/env perl

use strict;
use warnings;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use Carp;
use GetOpt::Long;

my $char_to_escape = "'";
my $escape_char = "\\";
my $n = 0;

GetOptions(
    'character-to-escape=s' => \$char_to_escape,
    'escape-character=s' => \$escape_char,
    'n=i' => \$n,
) or die "[!] ERROR: Issue parsing command line arguments...\n";

my $str_to_insert = $escape_char . $char_to_escape;

LINE:
while (<>) {
    my $line = $_;

    if ($n == 0) {
        $line =~ s/$char_to_escape/$str_to_insert/g;
    } else {
        my $cutoff_position = nth_index($line, $char_to_escape, $n);

        if ($cutoff_position != -1) {
            my $first_part = substr($line, 0, $cutoff_position);
            my $second_part = substr($line, $cutoff_position);

            $second_part =~ s/$char_to_escape/$str_to_insert/g;
            $line = $first_part . $second_part;
        }
    }

    print $line;
}

sub nth_index {
    my ($string, $substring, $n) = @_;
    my $current_position = 0;

    foreach my $time (1..$n) {
        $current_position = index($string, $substring, $current_position);
        last if $current_position == -1;
        $current_position++;
    }

    return $current_position;
}
