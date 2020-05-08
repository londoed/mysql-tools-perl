#!/usr/bin/env perl

# [!] USAGE: sql_export.pl [-l limit] [-d database] 'statement' > <output_file>

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

if ($host) {
  $options = "host=$host;" . $options;
}

getopts('d:l:pt');

my $database = $opt_d || $ENV{DB_DATABASE};
my $statement = shift(@ARGV) || usage();
my $dsn = $ENV{DB_DSN} || "DBI:$driver:database=$database;$options";
my $dbh = DBI->connect($dsn, $user, $password);

if (!defined($dbh)) {
  print "[!] ERROR: Unable to connect to database...";
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

my $row_hr;
my @keys;
my @field_list;

while (defined($row_hr = $sth->fetchrow_hasref())) {
  if ($opt_p) {
    print_para();
  } else {
    print_pipe();
  }

  if (defined($opt_l && $opt_l > 0)) {
    $opt_l--;
    last if ($opt_l == 0);
  }
}

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

sub print_pipe {
  if (!@field_list) {
    foreach my $k (sort(keys(%$row_hr))) {
      push(@field_list, lc($k));
      push(@keys, $k);
    }

    print join('|', @field_list), "\n";
  }

  foreach my $k (@keys) {
    if ($row_hr->{$k} =~ /\||\n/) {
      die "Pipe or newline in data field -- $k";
    }
  }

  print join('|', (map { $row_hr->{$_} } @keys)), "\n";
}

sub print_para {
  foreach my $k (sort(keys(%$row_hr))) {
    my $v = $row_hr->{$k};

    if ($v =~ /\n/) {
      die "Newline in data field -- $k";
    }

    printf "%s: %s\n", $k, $v;
  }

  print "\n";
}
