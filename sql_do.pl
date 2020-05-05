#!/usr/bin/env perl

# [!] USAGE: sql_do.pl [-d database] 'statement' > <output_file>

use strict;
use warnings;

use DBI qw();
use Getopt::Std qw(getopts);
use vars qw($opt_d $opt_l $opt_p $opt_t);

my $driver = $ENV{DB_DRIVER} || 'mysql';
my $host = $ENV{DB_HOST} || '';
my $user = $ENV{DB_USER} || '';
my $password = $ENV{DB_PASSWORD} || '';
my $options = $ENV{DB_OPTIONS} || '';
my @options;

if ($options) {
  push(@options, $options);
}

if ($host) {
  push(@options, $host);
}

getopts('d:l:pt');

if ($opt_d) {
  push(@options, "database=$opt_d");
}

my $statement = shift(@ARGV) || usage();
$options = join(';', @options);
my $dsn = $ENV{DB_DSN} || "DBI:$driver:$options";
my $dbh = DBI->connect($dsn, $user, $password);

if (!defined($dbh)) {
  print "[!] ERROR: Unable to connect to database...\n";
  exit(3);
}

$dbh->{LongReadLen} = 16384;

if ($opt_t) {
  $dbh->do("LOCK TABLES $opt_t READ");
}

my $sth = $dbh->prepare($statement);

if (!defined($sth)) {
  print "[!] ERROR: Unable to prepare sql: ", $dbh->errstr(), "\n";
  exit(4);
}

$sth->execute();
$sth->finish();

if ($opt_t) {
  $dbh->do("UNLOCK TABLES");
}

my $rv = $dbh->disconnect();

if ($rv != 1) {
  print "[!] ERROR: Something went wrong with disconnect -- $rv\n";
  exit(6);
}

exit(0);

sub usage() {
  die "[!] USAGE: sql_do.pl -d <database> 'statement' > <output_file>\n";
}
