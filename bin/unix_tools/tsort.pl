#!/usr/bin/env perl

use strict;
use warnings;
use vars qw<$opt_b, $opt_d>;
use Getopt::Std;

my $usage = "[!] USAGE: $0 [-b | -d] [filename]\n";
getopts("bd") or die $usage;

die $usage if ($opt_b && $opt_d);

my %pairs;
my %npred;
my %succ;

while (<>) {
    my ($l, $r) = my @l = split;
    next unless @l == 2;
    next if defined $pairs{$l}{$r};

    $pairs{$l}{$r}++;
    $npred{$l} = 0;
    ++$npred{$r};
    push @{$succ{$l}}, $r;
}

my @list = grep { !$npred($_) } keys %npred;

while (@list) {
    $_ = pop @list;
    print "$_\n";

    foreach my $child (@{$succ{$_}}) {
        if ($opt_b) {
            unshift @list, $child unless --$npred{$child};
        } else {
            push @list, $child unless --$npred{$child};
        }
    }
}

warn "[!] WARNING: Cycle detected\n" if grep { $npred{$_} } keys %npred;
