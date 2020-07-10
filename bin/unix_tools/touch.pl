#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Std;

sub parse_time($);
my ($VERSION) = '1.0';
my $warnings = 0;

$SIG {__WARN__} = sub {
    require File::Basename;
    $0 = File::Basename::basename($0);

    if (substr($_[0], 0, 14) eq "Unknown option") {
        warn <<EOF
$0 $VERSION
$0 [-acfm] [-r file] [-t [[CC]YY]MMDDhhmm[.SS]] file [files ...]
EOF
        exit;
    } else {
        $warnings = 1;
        warn "[!] WARNING: $_\n";
    }
};

$SIG {__DIE__} = sub {
    require File::Basename;
    $0 = File::Basename::basename($0);
    die "[!] ERROR: $_\n";
};

getopts('acmfr:t:', \my %options);
warn "[!] WARNING: Unknown options" unless @ARGV;

my $access_time = exists $options{a} || !exists $options{m};
my $modification_time = exists $options{m} || !exists $options{a};
my $no_create = exists $options{c};

my ($atime, $mtime, $special_time);

if ($options{r}) {
    ($atime, $mtime) = (stat $options{r}) [8, 9] or die "[!] ERROR: $options{r} -- $!\n";
    $special_time = 1;
} elsif ($options{t}) {
    $atime = $mtime = parse_time($options{t});
    die "[!] ERROR: -t $options{t} -- Time out of range!\n" if $atime < 0;
    $special_time = 1;
} else {
    $atime = $mtime = time;
}

foreach my $file (@ARGV) {
    unless (-f $file) {
        next if $no_create;
        local *FILE;
        require Fcntl;

        sysopen FILE, $file, Fcntl::O_CREAT() or do {
            warn "[!] WARNING: $file -- $!\n";
            next;
        };

        close FILE;
        next unless $special_time;
    }

    my ($aorig, $morig) = (stat $file) [8, 9] or do {
        warn "[!] WARNING: $file -- $!\n";
        next;
    };

    my $aset = $access_time ? $atime : $aorig;
    my $mset = $modification_time ? $mtime : $morig;

    utime $aset, $mset, $file or do {
        warn "[!] WARNING: $file -- $!\n";
        next;
    };
}

exit $warnings;

sub parse_time($) {
    my $time = shift;

    my ($first, $seconds) = split /\./ => $time, 2;
    my $year;

    if ($first =~ /\D/) {
        die "[!] ERROR: $time -- illegal time format\n"
    }
}
