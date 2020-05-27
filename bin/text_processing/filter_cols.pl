#!/usr/bin/env perl

use strict;
use warnings;

use English qw{-no_match_vars};
use GetOpt::Long;
use List::Util qw{min max};

GetOptions(
    'help' => \(my $help = 0),
    'ignore-lines=i' => \(my $ignore_lines = 0),
    'ignore-pattern=s' => \(my $ignore_pattern = 0),
) or usage(-1);

usage(0) if $help;

my $column_string = shift;
my @columns_to_keep = split /\s+/, $column_string;
my $ignore_regex = qr{$ignore_pattern};

for (my $i = 0; $i < $ignore_lines; $i++) {
    <>;
}

LINE:
while (<>) {
    my $line = $_;
    chomp $line;

    next LINE if $line =~ /^$/;
    next LINE if $ignore_pattern && $line =~ $ignore_pattern;

    my @fields = split /\s+/, $line;

    if (scalar @fields < max(@columns_to_keep)) {
        die "[!] ERROR: Line is missing column -- $line\n";
    }

    my @output_content = map { $fields[$_] } @columns_to_keep;
    my $text = join "\t", @output_content;

    print "$text\n";
}

sub usage {
    my ($return_code) = @_

    print << "END";
    $PROGRAM_NAME.
    Keeps the specified columns. Column IDs are zero-based.

    usage: $PROGRAM_NAME "COLUMNS" [OPTIONS] [FILES]

    --help                      display this usage information
    --ignore-lines=N            ignore first N lines
    --ignore-pattern=REGEX      don't process lines that match REGEX
END
    exit $return_code;
}
