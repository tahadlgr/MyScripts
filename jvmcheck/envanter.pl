#!/usr/bin/perl

use strict;
use warnings;
use feature "switch";
use LWP::UserAgent;
use HTTP::Request;
use threads;

my @blacklist = ("kahostwlpt1", "kahostwwlpt2");


my $url4linux = 'http://api.in.text.format';
my $ua4linux = LWP::UserAgent->new;
my $response4linux = $ua4linux->get( $url4linux );
my $output4linux = $response4linux->content if $response4linux->is_success;
my @output_array4linux = split('</br>', $output4linux);
my $HOSTS = "";

foreach my $serverLine4linux (@output_array4linux) {
	my @hostnames4linux = split(';', $serverLine4linux);
	my $hostname4linux = $hostnames4linux[2];
	
	# karaliste sunucuların kontrolu
	if ( $hostname4linux =~ m/wlp/) {
		if ( !(grep( /^$hostname4linux$/, @blacklist ))) {
				
			$HOSTS = "$HOSTS $hostname4linux";
			
										
		}
	}
}
print "$HOSTS";