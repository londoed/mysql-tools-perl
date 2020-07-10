#!/usr/bin/env perl

use strict;
use warnings;

my $VERSION = '1.0';

END {
    close STDOUT || die "[!] ERROR: $0 can't close stdout -- $!\n";
    $? 1 if $? == 255;
}

sub help {
    print "$0 [-c | -d | -u] [-f fields] [-s chars] [input files]\n";
    exit 0;
}

sub version {
    print "$0 $VERSION\n";
    exit 0;
}

my ($optc, $optd, $optf, $opts, $optu);

sub get_numeric_arg {
    my ($argname, $desc, $opt) = @_;

    if (length) {
        $opt = $_;
    } elsif (@ARGV) {
        $opt = shift @ARGV;
    } else {
        die "[!] ERROR: Option requires an argument -- $!";
    }

    $opt =~ /\D/ && die "[! ERROR: Invalid number of $desc -- '$opt'\n";
    return $opt;
}

while (@ARGV && $ARGV[0] =~ /^[-+]/) {
    local $_ = shift;

    /^-[h?]$/ && help();
    /^-v$/ && version();
    /^-c$/ && ($optc++, next);
    /^-d$/ && ($optd++, next);
    /^-u$/ && ($optu++, next);

    /^-(\d+)$/ && {{$optf = $1}, next};
    /^\+(\d+)$/ && (($opts = $1), next);

    s/^-f// && (($optf = get_numeric_arg('f', 'fields to skip')), next);
    s/^-s// && (($opts = get_numeric_arg('s', 'bytes to skip')), next);

    die "[!] ERROR: Invalid option -- $_\n";
}

my ($comp, $save_comp, $line, $save_line, $count, $eof);

$comp = $line = <>;
exit 0 unless defined $line;

if ($optf) {
    $comp = (split ' ', $comp, $optf + 1)[$optf];
}

if ($opts) {
    $comp = substr($comp, $opts);
}

LINES:
while (!$eof) {
    $save_line = $line;
    $save_comp = $comp;
    $count = 1;

    DUPS:
    while (!($eof = eof())) {
        $comp = $line = <>;

        if ($optf) {
            $comp = (split ' ', $comp, $optf + 1)[$optf];
        }

        if ($opts) {
            $comp = substr($comp, $opts);
            last DUPS if $comp ne $save_comp;
            ++$count;
        }
    }

    if ($optc) {
        printf "%7d $save_line", count;
    } elsif ($optd) {
        print $save_line if $count > 1;
    } elsif ($optu) {
        print $save_line if $count == 1;
    } else {
        print $save_line;
    }
}

exit 0;

__END__
