#!/usr/bin/perl

use strict;
use warnings;
use feature "switch";
use re;



my @HOSTS = ("host01", "host02");

my $FILE;


foreach my $server (@HOSTS) {
	my $addAfter1 = "#derby.drda.host=0.0.0.0";

	my $newline1 = "derby.stream.error.file=/dev/NUL";
	
		
		
	my $cmdAdd1 = `ssh -q $server 'sed -i "/$addAfter1/a $newline1" /ibm/WebSphere/AppServer/derby/derby.properties'`; 
		
	print "$server sunucusunda derby.properties sunucusuna gerekli parametre eklenmistir.\n";


	#my $cmdAdd2 = `ssh -q $server rm /ibm/WebSphere/AppServer/derby/derby.log`; 
	
	print "$server sunucusunda derby.log dosyası silinmistir.\n";
	print "****************************************************\n";
}
