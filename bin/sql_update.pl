#!/usr/bin/env perl

# [!] USAGE: sql_update.pl tablename keyfield < <input file>

use strict;
use warnings;

use DBI qw();
use Getopt::Std qw(getopts);
use vars qw($opt_c $opt_d $opt_s $opt_t);

my $driver = $ENV{DB_DRIVER} || 'mysql';
my $host = $ENV{DB_HOST} || '';
my $user = $ENV{DB_USER} || '';
my $password = $ENV{DB_PASSWORD} || '';
my $options = $ENV{DB_OPTIONS} || '';

if ($host) {
  $options = "host=$host;" . $options;
}

getopts('cd:s:t');

my $database = $opt_d || $ENV{DB_DATABASE};
my $dsn = $ENV{DB_DSN} || "DBI:$driver:database=$database;$options";
my $dbh = DBI->connect($dsn, $user, $password);

if (!defined($dbh)) {
  print "[!] ERROR: Unable to connect to database...\n";
  exit(3);
}

$dbh->{LongReadLen} = 16384;
$dbh->{AutoCommit} = 0;

if ($opt_s) {
  $dbh->do("SET SCHEMA $opt_s");
}

my $table = shift(@ARGV) || usage();
my $keyfield = shift(@ARGV) || usage();
my $field;
chop($fields = <STDIN>);
my @field_list = split(/\|/, $fields);
my @fields;
my $key_found = 0;

foreach (@field_list) {
  if ($_ eq $keyfield) {
    $key_found = 1;
  } else {
    push(@fields, $_);
  }
}

if (!$key_found) {
  die "[!] ERROR: Keyfield $keyfield not in input file";
}

if ($opt_t) {
  $dbh->do("LOCK TABLES $table WRITE");
}

my $sql = "UPDATE $table SET " .
  join(',', map { "$_ = ?" } (@fields)) .
  "WHERE $keyfield = ?";

print "SQL is $sql\n";

my $sth = $dbh->prepare($sql);

if (!defined($sth)) {
  print "[!] ERROR: Unable to prepare SQL -- ", $dbh->errstr(), "\n";
  exit(4);
}

my @data;
my @bound;
my $rv;
my $rc = 0;
my $v;
my $rows = 0;

while (<STDIN>) {
  chop;
  my $line = $_;
  @data = split(/\|/);
  @bound = ();
  my $key;

  foreach (@field_list) {
    if ($_ eq $keyfield) {
      $key = shift(@data);
    } else {
      $v = shift(@data);
      $v = undef if ($v eq '');
      push(@bound, $v);
    }
  }

  $rv = $sth->execute(@bound, $key);

  if ($rv != 1) {
    print "[!] ERROR: Update encountered an error on line ($line) -- ", $sth->errstr(), "\n";
    print "Bound was (", join(',', @bound), ") and key was ($key)\n";
    $rc = 8;
  }

  if ($opt_t && (++$row % 1000) == 0) {
    $dbh->do("UNLOCK TABLES");
    $dbh->do("LOCK TABLES $table WRITE");
  }
}

if ($opt_t) {
  $dbh->do("UNLOCK TABLES");
}

$sth->finish();

if ($opt_c) {
  $dbh->commit();
  print "[!] ATTENTION: Committed";
} else {
  $dbh->rollback();
  print "[!] ATTENTION: Rolled Back (use -c next time)\n";
}

$rv = $dbh->disconnect();

if ($rv != 1) {
  print "[!] ERROR: Something went wrong on disconnect -- $rv\n";
  exit(6);
}

exit($rc);

sub usage {
  die "[!] USAGE: sql_update.pl [-d database] tablename keyfield < <input_file>\n";
}
