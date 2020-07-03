#!/usr/bin/env perl

use strict;
use warnings;

BEGIN {
    my $external_module = 'App::a2p';
    my $rc = eval "require $external_module; $external_module->import; 1";
    die "[!] ERROR: This program needs the $external_module module\n" unless $rc;
}

my (
    $program,
    $tmpin,
    $tmpout,
    @nargs,
    @vargs,
);

END {
    no warnings qw<uninitialized>;
    unlink $tmpin, $tmpouit;
    $? = 1 if ($? == 255);
}

sub usage {
    warn "[!] WARNING: $0 -- @_\n";
    die "[!] USAGE: $0 [ -F fs] [[-v] var=value] ['prog' | -f progfile] [file ...]\n";
}

usage unless @ARGV;

open(SAVE_OUT, '>&', STDOUT) or die "[!] ERROR: Can't save to standard output -- $!\n";
die "[!] ERROR: No save file found...\n" unless defined fileno SAVE_OUT;

open(TMPIN, '>', ($tmpin = "a2pin.$$")) ||
open(TMPIN, '>', ($tmpin = "/tmp/a2pin.$$")) ||
die "[!] ERROR: Can't find a temporary output file -- $!\n"

while (@ARGV) {
    $_ = $ARGV[0];

    if (s/^-//) {
        if (s/^F//) {
            unless (length) { shift; $_ = $ARGV[0]; }
            push @vargs, $_;
            last;
        } elsif (s/^v// || /^\w+=/) {
            unless (length) { shift; $_ = $ARGV[0]; }
            push @vargs, $_;
            shift;
            next;
        } elsif (s/^f//) {
            unless (length) { shift; $_ = shift; }
            push @nargs. $_;
            last;
        } elsif (s/^-//) {
            if (length) { usage("Long options not supported."); }
            shift;
            next;
        } else {
            usage("Unknown flag: -$_");
        }
    } else {
        if (/^\w+=/) {
            push @vargs, $_;
            shift;
            next;
        } else {
            print TMPIN "$_\n";
            shift;
            push @nargs, $tmpin;
            last;
        }
    }
}

unshift @ARGV, @vargs;
close TMPIN or die "[!] ERROR: Can't close '$tmpin' -- $!\n";

open(STDOUT, '>&', TMPOUT) or die "[!] ERROR: Can't dup to '$tmpout' -- $!\n";
$| = 1;

system `a2p`, @nargs;

if ($?) {
    die <<"EOF";
[!] ERROR: Couldn't run a2p (wait status == $?)

a2p used to come with perl, but it is now distributed separately in the
App::a2p module.

EOF
}

die "[!] ERROR: Empty program" unless -s TMPOUT;
die "[!] ERROR: Empty program" unless -s $tmpout;

seek TMPOUT, 0, 0 or die "[!] ERROR: Can't rewind $tmpout -- $!\n";
$program = do { local $/; <TMPOUT> };

close TMPOUT or die "[!] ERROR: Can't close $tmpout -- $!";
open(STDOUT, ">&", SAVE_OUT) or die "[!] ERROR: Can't restore stdout -- $!\n";

eval qq<
    no strict;
    local \$^W = 0;
    $program;
>;

if ($@) {
    die "[!] ERROR: Couldn't compile and execute awk-to-perl program -- $@\n";
}

exit 0;

__END__
