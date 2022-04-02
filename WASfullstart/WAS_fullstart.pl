#!/usr/bin/perl

use strict;
use warnings;
use feature "switch";
use re;

my $sv_name = "";

my $server = $ARGV[0];
$server = lc $server;

print "$server sunucusunda gerekli islemler baslatiliyor.\n";

my $charnum = (split//, $server);

foreach my $i (0..($charnum-3)) {
      my $chars1 =(split//, $server)[$i];
	  $sv_name .= "$chars1";
}
chomp($sv_name);


my $last_num = (split//, $server)[-1];
chomp($last_num);

my $last1_num = (split//, $server)[-2];
chomp($last1_num);

my $sv_num = "$last1_num"."$last_num";
chomp($sv_num);

my $sv1_name = "$sv_name"."01";
chomp($sv1_name);

my $full_name = "$sv_name"."$sv_num";


if($sv_num == 01){
	print "$server sunucusunda DMGR aciliyor.\n";
	my $dmgr =`ssh -q $server bash /ibm/isbank_profiles/dmgr/bin/startManager.sh`;
}

print "$server sunucusundaki nodeagent dmgr ile sync ediliyor.\n";
my $sync =`ssh -q $server bash /ibm/isbank_profiles/node$sv_num/bin/syncNode.sh $sv1_name`;

print "Node start ediliyor.\n";
my $node = `ssh -q $server bash /ibm/isbank_profiles/node$sv_num/bin/startNode.sh`;

print "***Gerekli islemler tamamlanmistir. Konsoldan JVM'leri acabilirsiniz.***\n\n ";