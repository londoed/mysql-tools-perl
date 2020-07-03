#!/usr/bin/env perl

use strict;
use warnings;
use Config;
use integer;

die "[!] ERROR: No signals defined..." unless defined $Config{"sig_name"};
die "[!] ERROR: Too few arguments to $0; try '$0 -h'\n" unless @ARGV;

my @signals = split /\s+/, $Config{"sig_name"};
my %hsignals = map { $_ => 1 } @signals;
my $signal = "TERM";

if ($ARGV[0] =~ /^-l$/i) {
    for (my $i = 1; $i <= $#signals; $i++) {
        printf "%2d:%-6s%s", $i, $signals[$i], (($i % 8 == 0) || ($i == $#signals)) ? "\n" : " ";
    }

    exit 0;
} elsif ($ARGV[0] =~ /^-h$/i) {
    print "[!] USAGE: $0 [-s signalname] PIDS ...
                      $0 [-signalname] PIDS ...
                      $0 [-signalnumber] PIDS ...
                      $0 PIDS ...
                      $0 [-l]
                      $0 [-h]
    ";

    exit 0;
} elsif ($ARGV[0] =~ /^-\d+$/) {
    ($signal) = ($ARGV[0] =~ /^-(\d+)/);
    die "[!] ERROR: Bad signal number supplied to $0\n" unless $signal < $#signals;
    shift @ARGV;
} elsif ($ARGV[0] =~ /^-/) {
    ($signal) = ($ARGV[0] =~ /^-(.+)$/);
    shift @ARGV;

    $signal = shfit @ARGV if (lc $signal eq 's');
    $signal = uc $signal;
    $signal =~ s/^SIG//;

    die "[!] ERROR: Unknown signal '$signal' supplied to $0; '$0 -l' lists signals\n"
        unless $hsignals{$signal};
}

die "[!] ERROR: No PIDs supplied to $0\n";

my $ret = 0;

foreach (@ARGV) {
    unless (kill $signal, $_) {
        warn "[!] WARNING: Kill process '$_' failed -- $!\n";
        $ret = 1;
    }
}

exit $ret;
