#!/usr/bin/env perl

# [!] USAGE: sql_insert.pl [-d database] [-e] [-l] [-t tablename] [-z] < <input file>

use strict;
use warnings;

use DBI qw();
use Getopt::Std qw(getopts);
use vars qw($opt_d $opt_e $opt_l $opt_t $opt_z);

my $driver = $ENV{DB_DRIVER} || 'mysql';
my $host = $ENV{DB_HOST} || '';
my $user = $ENV{DB_USER} || '';
my $password = $ENV{DB_PASSWORD} || '';
my $options = $ENV{DB_OPTIONS} || '';

if ($host) {
  $options = "host=$host;" . $options;
}

getopts('d:e:lt:z');

my $database = $opt_d || $ENV{DB_DATABASE};
$opt_t || usage();
my $max_errors = $opt_e || 0;
my $dsn = $ENV{DB_DSN} || "DBI:$driver:database=$database;$options";
my $dbh = DBI->connect($dsn, $user, $password);

if (!defined($dbh)) {
  print "[!] ERROR: Unable to connect to database...\n";
  exit(3);
}

my $line_num = 0;
my $fields;
chop($fields = <STDIN>);
my @field_list = split(/\|/, $fields);

if ($opt_l) {
  $dbh->do("LOCK TABLES $opt_t WRITE");
}

if ($opt_z) {
  my $sth = $dbh->prepare("DELETE from $opt_t");
  $sth->execute();
}

my $stmt = "INSERT into $opt_t (" .
  join(',', @field_list) .
  ') VALUES (' .
  join(',', (map { '?' } @field_list)) .
  ')';

print "[...] Inserting into $opt_t\n";

my $sth = $dbh->prepare($stmt);

if (!defined($sth)) {
  print "[!] ERROR: Unable to prepare SQL -- ", $dbh->errstr(), "\n";
  exit(4);
}

my @data;
my @bound;
my $rv;
my $rc = 0;
my $v;
my $row_count = 0;
my $errors = 0;

while (<STDIN>) {
  chomp;
  $line_num++;

  my $line = $_;
  @data = split(/\|/);
  @bound = ();

  foreach (@field_list) {
    $v = shift(@data);
    $v = undef if ($v eq 'undef');
    push(@bound, $v);
  }

  $rv = $sth->execute(@bound);

  if ($rv != 1) {
    print "[!] ERROR: Failed to insert ($line) -- ", $sth->errstr(), "\n";
    $rc = 8;
    $errors++;

    if ($max_errors && $errors > $max_errors) {
      print "[!] ATTENTION: Too many errors, exiting...";
      last;
    }
  }

  $row_count++;

  if ($opt_l && ($row_count % 1000) == 0) {
    $dbh->do("UNLOCK TABLES");
    $dbh->do("LOCK TABLES $opt_t WRITE");
  }
}

$sth->finish();

print "[!] SUCCESS: Inserted $row_count rows into table $opt_t\n";

if ($opt_l) {
  $dbh->do("UNLOCK TABLES");
}

$rv = $dbh->disconnect();

if ($rv != 1) {
  print "[!] ERROR: Something went wrong on disconnect -- $rv\n";
  exit(6);
}

exit($rc);

sub usage {
  print STDERR "[!] USAGE: sql_insert.pl [-d database] [-e max_errors] [-l] [-t table_name] [-z] < <input_file>\n";
  print STDERR <<EOF;
-l    Lock Tables
-z    Zero table (delete everything before insert)
EOF

  exit(8);
}
