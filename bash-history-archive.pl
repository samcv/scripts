#!/usr/bin/env perl
# Copyright 2016 Samantha McVey <samantham@posteo.net>
# Licensed under the GPLv3
#
# A program to save bash history files to files named after the typed date.
use strict;
use warnings;
my $home = $ENV{HOME};
chomp $home;
my($year, $month, $day);
my $current_epoch = time();
my $last_archive_epoch = `cat ~/bash-history/last-date`;
if ($last_archive_epoch eq "") {
  $last_archive_epoch = 0;
}
my $tempfile = $home . '/bash_history_temp';
my $archive_dir = $home . "/bash-history";
`mkdir -p $archive_dir`;
open(my $in, '<', "$home/.bash_history" ) or die("Could not open file: $!");
open my $out, '>', "$tempfile" or die "Can't write new file: $!";
#date '+%m/%d/%y %H:%M:%S' -d @147306792
my $is_cmd_line = 0;
my $skip = 0;

foreach my $line (<$in>) {
  chomp $line;
  if ($is_cmd_line == 1) {
    $is_cmd_line = 0;
    open my $dated_file, '>>', "$archive_dir/$year-$month-$day-bash_history.txt" or die "Could not open file: $!";
    print $dated_file "$line\n";
    close $dated_file;
  }
  elsif ( $skip == 1 ) {
    $skip = 0;
    last;
  }
  elsif ($line =~ /^#[0-9]+/) {
    $line =~ s/^#//;
    if ($line < $last_archive_epoch) {
      $skip = 1;
      last;
    }
    my $cmd = "date '+%Y/%m/%d %H:%M:%S' -d @" . "$line";
    my $date = `$cmd`;
    chomp $date;
    #print "date: $date\n";
    ($year, $month, $day) = split /\//, $date, 3;
    $day =~ s/ .*//;
    #print "year: $year month: $month day: $day\n";
    open my $dated_file, '>>', "$archive_dir/$year-$month-$day-bash_history.txt" or die "Could not open file: $!";
    print $dated_file "$date  ";
    $is_cmd_line = 1;
    close $dated_file;

  }
  else {
    print $out "$line\n";
  }
}
close $in;
close $out;
`echo -n $current_epoch > ~/bash-history/last-date`;
