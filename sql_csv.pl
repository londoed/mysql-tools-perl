#!/usr/bin/env perl

# [!] USAGE: sql_csv.pl <tablename> <fieldname> ... > <output file>

use strict;
use warnings;

use DBI qw();

my $driver = 'mysql';
my $host = $ENV{DB_HOST} || '';
my $user = 'londoed';
my $password = '';
my $options = '';

if ($host) {
  $options = "host=$host;" . $options;
}

my $database = shift(@ARGV) || die "[!] ERROR: Database name is required...";
my $table = shift(@ARGV);

if ($table eq '') {
  print STDERR "[!] USAGE: sql_csv.pl <tablename> <fieldname> ... > output.file\n";
  exit(4);
}

my @field_list = @ARGV;

if (!@field_list) {
  print STDERR "[!] ERROR: No field supplied!\n";
  exit(4);
}

print join(',', (map { "\"$_\"" } @field_list)), "\n";

my $dsn = "DBI:$driver:database=$database;$options";
my $dbh = DBI->connect($dsn, $user, $password);

if (!defined($dbh)) {
  print "[!] ERROR: Unable to connect to database!\n";
  exit(3);
}

my $sql = "SELECT " . join(',', @field_list) . " FROM $table";

$dbh->do("LOCK TABLES $table READ");

my $sth = $dbh->prepare($sql);

if (!defined($sth)) {
  print "Unable to prepare sql: ", $dbh->errstr(), "\n";
  exit(4);
}

$sth->execute();

while (@row = $sth->fetchrow_array()) {
  my @v;
  my $value;

  foreach (@row) {
    if (/[",]/) {
      $value = $_;
      $value =~ s/"/""/g;
      $value = '"' . $value . '"';
      push(@v, $value);
    } else {
      push(@v, $_);
    }
  }

  print join(',', @v), "\n";
}

$sth->finish();
$dbh->do("UNLOCK TABLES");

my $rv = $dbh->disconnect();

if ($rv != 1) {
  print "[!] ERROR: Something went wrong with disconnect -- $rv\n";
  exit(6);
}

exit(0);
