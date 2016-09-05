#!/usr/bin/env perl
# Copyright 2016 Samantha McVey <samantham@posteo.net>
# Licensed under the GPLv3
#
# A program to save bash history files to files named after the typed date.
use strict;
use warnings;

my $home = $ENV{HOME};
chomp $home;
# Declare year month date outside of the 'foreach' loop so we can access it
# in the next iteration of the loop
my ( $year, $month, $day );
my $current_epoch      = time();
my $last_archive_epoch = `cat ~/bash-history/last-date`;
# If there is no file or it's empty, set $last_archive_epoch to 0
if ( $last_archive_epoch eq "" ) {
	$last_archive_epoch = 0;
}
my $archive_dir = $home . "/bash-history";
`mkdir -p $archive_dir`;
open( my $histfile, '<', "$home/.bash_history" ) or die("Could not open file: $!");

my $is_cmd_line = 0;
my $skip        = 0;

foreach my $line (<$histfile>) {
	chomp $line;
	# If the last time the loop ran was a date, then is_cmd_line will equal 1
	# Indicating it is a saved command line.
	if ( $is_cmd_line == 1 ) {
		$is_cmd_line = 0;
		open my $dated_file, '>>',
			"$archive_dir/$year-$month-$day-bash_history.txt"
			or die "Could not open file: $!";
		print $dated_file "$line\n";
		close $dated_file;
	}
	# $skip will equal 1 if our last line we read was an epoch time before what
	# $last_archive_epoch is set to.
	elsif ( $skip == 1 ) {
		$skip = 0;
		last;
	}
	elsif ( $line =~ /^#[0-9]+/ ) {
		$line =~ s/^#//;
		if ( $line < $last_archive_epoch ) {
			$skip = 1;
			last;
		}
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
close $histfile;
# Write the epoch time the script was started to the last-date file
`echo -n $current_epoch > ~/bash-history/last-date`;
