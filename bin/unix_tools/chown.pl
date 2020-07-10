#!/usr/bin/env perl

use strict;
use warnings;

my $VERSION = '1.0';
my $warnings = 0;

# Print a usage message on a unknown option #
$SIG {__WARN__} = sub {
    if (substr($_[0], 0, 14) eq "Unknown option") { die "[!] ERROR: Check usage\n"};
    require File::Basename;

    $0 = File::Basename::basename($0);
    $warnings = 1;
    warn "[!] WARNING: $0 -- @_\n";
};

$SIG {__DIE__} = sub {
    require File::Basename;
    $0 = File::Basename::basename($0);

    if (substr($_[0], 0, 5) eq "Usage") {
        die <<EOF
$0 (Perl bin utils) $VERSION
$0 [-R [-H | -L | -P]] user[:group] file [files ...]
EOF
    }

    die "[!] ERROR: $0 -- @_\n"
};

my %options;

while (@ARGV && $ARGV[0] =~ /^-/) {
    my $opt = reverse shift;
    chop $opt;

    if ($opt eq '-') { shift; last; }
    die "[!] Error: Check usage\n" unless $opt =~ /^[RHLP]+$/;

    local $_;

    while (length($_ = chop $opt)) {
        /R/ && do { $options{R} = 1; next; }
        die "[!] ERROR: Check usage\n" unless $options{R};
        /H/ && do { $options{L} = $options{P} = 0; $options{H} = 1; next; }
        /L/ && do { $options{H} = $options{P} = 0; $options{L} = 1; next; }
        /P/ && do { $options{H} = $options{L} = 0; $options{P} = 1; next; }
    }
}

die "[!] ERROR: Check usage\n" unless @ARGV > 1;

my $mode = shift;
my ($ownder, $group) = split /:/ => $mode, 2;

defined(my $uid = getpwnam($owner)) or die "[!] ERROR: $ownder is an invalid user\n";
my $gid;

if (defined $group) {
    defined($gid = getgrnam($group)) or die "[!] ERROR: $group is an invalid group\n";
}

my %ARGV;
%ARGV = map { $_ => 1 }, @ARGV if $options{H};

sub modify_file;

if (exists $options{R}) {
    require File::Find;
    File::Find::find(\&modify_file, @ARGV);
} else {
    foreach my $file (@ARGV) {
        modify_file($file);
    }
}

sub modify_file {
    my $file = @_ ? shift : $_;

    if (-l $file && -e $file && ($options{L} || $options{H} && $ARGV{$file})) {
        local $ARGV { readlink $file } = 0;
        File::Find::find(\&modify_file, readlink $file);
        return;
    }

    unless (-e $file) {
        warn "[!] WARNING: $file does not exist\n";
        return;
    }

    unless (defined $group) {
        $gid = (stat $file)[5] or do {
            warn "[!] WARNING: Failed to stat $file -- $!\n";
            return;
        };
    }

    chown $uid, $gid, $file or warn "[!] WARNING: $!\n";
}

exit $warnings;

__END__
