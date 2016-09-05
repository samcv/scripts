#!/usr/bin/env perl
# Copyright 2016 Samantha McVey <samantham@posteo.net>
# Licensed under the GPLv3
#
# A program to save bash history files to files named after the typed date.
# By default saves files in ~/bash-history/YYYY-MM-DD-bash_history.txt
# It will also write to a file called last-archive-date
use strict;
use warnings;

my $home = $ENV{HOME};
chomp $home;
# Declare year month date outside of the 'foreach' loop so we can access it
# in the next iteration of the loop
my ( $year, $month, $day );
my $current_epoch = time();

my $archive_dir = $home . "/bash-history";
`mkdir -p $archive_dir`;
open my $hist_file, '<', "$home/.bash_history" or die("Could not open file: $!");


# Get the last archived date
my $use_epoch_file = 1;
my $last_archive_epoch;
open my $fh, '<', "$archive_dir/last-archive-date" or $use_epoch_file = 0;
if ($use_epoch_file == 1 ) {
  $last_archive_epoch = do { local $/ = undef ; <$fh> };
  chomp $last_archive_epoch;
  close $fh;
}
# If there is no file or it's empty, set $last_archive_epoch to 0
else {
  $last_archive_epoch = 0;
}
# If the last time the loop ran was a date, then is_cmd_line will equal 1
# Indicating the next line is a saved command line to be printed to the file..
my $is_cmd_line = 0;
# $skip will equal 1 if our last line we read was an epoch time before what
# $last_archive_epoch is set to.
my $skip        = 0;

foreach my $line (<$hist_file>) {
	chomp $line;

	if ( $is_cmd_line == 1 ) {
		$is_cmd_line = 0;
		open my $dated_file, '>>',
			"$archive_dir/$year-$month-$day-bash_history.txt"
			or die "Could not open file: $!";
		print $dated_file "$line\n";
		close $dated_file;
	}
	elsif ( $line =~ /^#[0-9]+/ ) {
		$line =~ s/^#//;
		if ( $line < $last_archive_epoch ) {
      $skip = 1;
		}
    if ($skip == 1) {
      $skip = 0;
    }
    else {
  		my $cmd  = "date '+%Y/%m/%d %H:%M:%S' -d @" . "$line";
  		my $date = `$cmd`;
  		chomp $date;
  		( $year, $month, $day ) = split /\//, $date, 3;
  		$day =~ s/ .*//;
  		open my $dated_file, '>>',
  			"$archive_dir/$year-$month-$day-bash_history.txt"
  			or die "Could not open file: $!";
  		print $dated_file "$date  ";
  		$is_cmd_line = 1;
  		close $dated_file;
    }

	}

}
close $hist_file;
# Write the epoch time the script was started to the last-archive-date file
open my $fh2, '>', "$archive_dir/last-archive-date" or die "can't open last-archive-date: $!";
print $fh2 "$current_epoch\n";
close $fh2;
