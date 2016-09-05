#!/usr/bin/env perl
# Copyright 2016 Samantha McVey <samantham@posteo.net>
# Licensed under the GPLv3
#
# A program to save bash history files to files named after the typed date.
use strict;
use warnings;
my $home = `echo \$HOME`;
my $tempfile = 'bash_history_temp';
chomp $home;

open(my $in, '<', "$home/.bash_history" ) or die("Could not open file: $!");
open my $out, '>', "$home/$tempfile" or die "Can't write new file: $!";
#date '+%m/%d/%y %H:%M:%S' -d @147306792
my $var = 0;
foreach my $line (<$in>) {
  chomp $line;
  if ($var == 1) {
    $var = 0;
    print $out "$line\n";
  }
  elsif ($line =~ /^#[0-9]+/) {
    $line =~ s/^#//;
    my $cmd = "date '+%Y/%m/%d %H:%M:%S' -d @" . "$line";
    my $date = `$cmd`;
    chomp $date;
    print $out "$date  ";
    $var = 1;
  }
  else {
    print $out "$line\n";
  }
}
close $in;
close $out;


open my $in2, '<', "$home/$tempfile" or die "Could not open file: $!";
foreach my $line2 (<$in2>) {
  chomp $line2;
  if ($line2 =~ /^[0-9][0-9][0-9][0-9]/) {
    my($year, $month, $day) = split /\//, $line2, 3;
    $day =~ s/ .*//;
    open my $dated_file, '>>', "$home/$year-$month-$day-bash_history.txt" or die "Could not open file: $!";
    print $dated_file "$line2\n";
    close $dated_file;
  }
}
`rm $home/$tempfile`
