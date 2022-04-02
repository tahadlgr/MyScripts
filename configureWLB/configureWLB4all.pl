#!/usr/bin/perl -w


use POSIX qw(strftime);
use strict;
use warnings;
use feature "switch";
use LWP::UserAgent;
use HTTP::Request;
use threads;
use re;




my $datestring = strftime "%F", localtime;

print "$datestring tarihli dosyadaki sunucu listesi için işlem yapılacaktır. \n";

chomp($datestring);

my $src = "/usy/liberty/configureWLB/dates/${datestring}.pl";

our ( $arr );

require $src;

my @whitelist = split (' ', $arr);



# --- Clear Logs & Alerts of Previous Turn ---
my $clearLog  = "echo -n '' > /usy/liberty/configureWLB/logs/configure4All.log";
system($clearLog);

my @blacklist = ("hostnamet1", "hostnamet2");


# --- Fetching Linux UAT Servers Dynamically --- 
my $url4linux = 'http://api_in_text_format';
my $ua4linux = LWP::UserAgent->new;
my $response4linux = $ua4linux->get( $url4linux );
my $output4linux = $response4linux->content if $response4linux->is_success;
my @output_array4linux = split('</br>', $output4linux);

foreach my $serverLine4linux (@output_array4linux) {
	my @hostnames4linux = split(';', $serverLine4linux);
	my $hostname4linux = $hostnames4linux[2];
	$hostname4linux = lc $hostname4linux;
	
	
	# karaliste sunucuların kontrolu
	if ( $hostname4linux =~ m/wlp/ && grep( /^$hostname4linux$/, @whitelist )) {
	
		print "*************************\n\n";
		
		print "Sunucu Adi: " . $hostname4linux . "\n";
		my $cmd = `perl /usy/liberty/configureWLB/configureWLB.pl $hostname4linux >> /usy/liberty/configureWLB/logs/configure4All.log`;
			
		print "\n\n*************************\n\n";
	}else{
		print "*************************\n\n";
		print "$hostname4linux sunucusunda islem yapilmayacaktir!!!";
		print "\n\n*************************\n\n";
	}
}
my $cmd2 = `cat /usy/liberty/configureWLB/logs/configure4All.log >> /usy/liberty/configureWLB/logs/oldlogs.log`;