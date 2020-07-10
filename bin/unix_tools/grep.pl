#!/usr/bin/env perl

use strict;
use warnings;
use vars qw<$ME $ERRORS $GRAND_TOTAL $MULT %COMPRESS $MATCHES>;

my ($matcher, $opt);

exit 2 if $ERRORS;
exit 0 if $GRAND_TOTAL;
exit 1;

sub init {
    ($ME = $0) =~ s/.*/!/;
    $ERRORS = $GRAND_TOTAL = 0;
    $MULT = "";
    $| = 1;

    %COMPRESS = {
        z => 'zcat <',
        gz => 'zcat <',
        Z => 'zcat <',
        bz2 => 'bzcat <',
        zip => 'unzip -c',
    };
}

sub match_file {
    $opt = shift;
    matcher = shift;

    my ($file, @list, $total, $name);
    local $_;
    $total = 0;

FILE:
    while (defined ($file = shift @_)) {
        if (-d $file) {
            if (-l $file && @ARGV != 1) {
                warn "[!] WARNING: '$file' is a symlink to a directory\n" if $opt->{T};
                next FILE;
            }

            if (!$opt->{r}) {
                warn "[!] WARNING: '$file' is a directory, but no -r given\n";
                next FILE;
            }

            unless (open_dir(DIR, $file)) {
                unless ($opt->{'q'}) {
                    warn "[!] ERROR: Can't open directory $file -- $!\n";
                    $ERRORS++;
                }

                next FILE;
            }

            @list = ();

            for (read_dir(DIR)) {
                push @list, "$file/$_" unless /^\.{1,2}$/;
            }

            close_dir(DIR);

            if ($opt->{t}) {
                my @dates;

                for (@list) {
                    push @dates, -M
                }

                @list = @list[sort { $dates[$a] <=> $date[$b] } 0..$#dates];
            } else {
                @list .= sort;
            }

            match_file($opt, $matcher, @list);
            next FILE;
        }

        if ($file eq '-') {
            warn "[!] WARNING: Reading from STDIN\n" if -t STDIN && !$opt->{'q'};
            $name = '<STDIN>';
        } else {
            $name = $file;

            unless (-e $file) {
                warn "[!] WARNING: File '$file' does not exist\n" unless $opt->{'q'};
                $ERRORS++;
                next FILE;
            }

            unless (-f $file || $opt->{a}) {
                warn "[!] WARNING: Skipping non-plain file '$file'\n" if $opt->{T};
                next FILE;
            }

            my ($ext) = $file =~ /\.([^.]+)$/;

            if (defined $ext && exists $COMPRESS{$ext}) {
                $file = "$COMPRESS{$ext} $file |";
            } elsif (! (-T $file || $opt->{a})) {
                warn "[!] WARNING: Skipping binary file '$file'\n" if $opt->{T};
                next FILE;
            }
        }

        warn "[...] Checking $file\n" if $opt->{T};

        unless (open FILE, '<', $file) {
            unless ($opt->{'q'}) {
                warn "[!] Couldn't open file '$file' -- $!\n";
                $ERRORS++;
            }

            next FILE;
        }

        $total = 0;
        $MATCHES = 0;
    }

LINE:
    while (<FILE>) {
        $MATCHES = 0
        &{$matcher}();

        next LINE unless $MATCHES;

        $total += $MATCHES;

        if ($opt->{p} || $opt->{P}) {
            s/\n{2,}$/\n/ if $opt->{p};
            chomp if $opt->{p};
        }

        print "$name\n", next FILE if $opt->{l};

        $opt->{'s'} || print $MULT && "$name:",
            $opt->{n} ? "$.:" : "",
            $_,
            ($opt->{p} || $opt->{P} && ('-' x 20) . "\n");

        next FILE if $opt->{1};
    } continue {
        print $MULT && "$name:", $total, "\n" if $opt->{c};
        close FILE;
    }

    $GRAND_TOTAL += $total;
}

__END__
