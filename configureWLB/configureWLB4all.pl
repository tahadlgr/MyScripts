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

my @blacklist = ("kaalgappt1", "kaalmofst1", "kaalmofst2", "kaofswast1", "kasasmett1", "klddmwast1", "klddmwast2", "klesasrrt1", "klesasrrt2", "klikbwlpt1", "klikbwlpt2", "klapicapt1", "klapicapt2", "klapicapt3", "klapicapt4", "klapicapt5", "klapicbtt1", "klapicift1", "klapicift2", "klapicift3", "klapicmat1", "klapicmat2", "klapicmat3", "klapicrtt1", "klapicrtt2", "kldpwlogt1", "kldpwlogt2", "klesawmat1", "klesawmat2", "klesawmit1", "klesawmit2", "klevmengt1", "klevmengt2", "klevmengt3", "klevmengt4", "klevmlsot1", "klevmlsot2", "klfcbtomt1", "klfcbtomt2", "klfcftomt1", "klfcftomt2", "klfcitomt1", "klfcitomt2", "klfcltomt1", "klfcltomt2", "klframont1", "klframont2", "klgeongxt1", "klgeongxt2", "klifasast1", "klifasast2", "klifasast3", "klifasast4", "klifcsast1", "klifmsast1", "kllmnb2bt1", "kllmnb2bt2", "kllmnsspt1", "kllmnsspt2", "klrrmsast1", "kltlfpcat2", "kltlfpcat3", "klusyappt1", "klusyappt2", "klusydomt1", "klusydstt1", "klxebdplt1", "klxebdplt2", "klxebjstt1", "klxebjstt2", "klxebjstt4", "klusymant1", "klusymant2", "kabfragtt1", "kasigwast1", "kasigwast2", "klcpawast3", "plesawmit1", "plesawmit2", "kacrmwast3", "kacrmwast4", "klcondckt1", "klcondckt2", "klcondckt3", "klcondckt4", "klesalogt2", "kllmnseat1", "klugwappt1", "klugwappt2", "klquawlpt1", "klquawlpt2", "klesabatt1", "klesabatt2", "klevmlsbt1", "klevmlsbt2", "klwfmbatt1", "klwfmbatt2", "klsodwlpt1");


# --- Fetching Linux UAT Servers Dynamically --- 
my $url4linux = 'http://uygulama.isbank/service/information.php?service=server&tip=4&ortam=PROD';
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