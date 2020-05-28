#!/usr/bin/env perl

use strict;
use warnings;

while (<@ARGV>) {
    if (/-f/) {
        shift;
        $seqfile = shift;
    }
}

unless ($seqfile) {
    print "\n[!] USAGE: perl make_seq.pl -f <file>\n";
    exit;
}

my $tmp = "temp.$$";
system "mv $seqfile $tmp";

open(SEQ, '>>', $seqfile) or die "[!] ERROR: Can't open SEQ output file\n";

print SEQ "Numevents ???\n";
print SEQ "event mode duration window SOA/ISI xpos ypos resp type filename\n";
print SEQ "----- ---- -------- ------ ------- ---- ---- ---- ---- --------\n";

my $event = 0;
my $mode = 'PCX';
my $dur = '0.2';
my $win = '1.0';
my $soa = '2.0';
my $xpos = '0.0';
my $ypos = '0.0';
my $resp = '1';
my $type = '0';
my $file = '';

open(TMP, "$tmp") or die "[!] ERROR: Can't open '$tmp', which is a copy of $seqfile\n";

while(<TMP>) {
    $event++;
    my @v = split;
    $type = $v[0];
    $file = $v[1];

    printf SEQ "%5s %4s %8s %6s %7s %4s %4s %4s %4s %-8s\n", $event, $mode, $dur, $win, $soa, $xpos, $ypos, $resp, $type, $file;
}

close SEQ;
close TMP;
system "rm -rf $tmp";
