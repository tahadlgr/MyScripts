#!/usr/bin/perl

use strict;
use warnings;
use feature "switch";
use re;

my $server = $ARGV[0];
$server = lc $server;

### SUNUCU TARAFINDAN GEREKLI BILGILERIN ALINMASI ###
my $FILES;
my $FILE;
my $FILEPATH;
my $dirNAME;
my $filename;
my $backupDizin;
my $jvmRestartFlag = 0;


print "********** ********** ********** ********** **********\n";
print "********** ********** ********** ********** **********\n\n";


###SUNUCUDAKI JVM SAYISI ###
my $numOfJVM = `ssh -q $server ls -ltr /ibm/servers | grep -v total | awk '{print NR, \$1}' | tail -1 | awk '{print \$1}'`;
chomp($numOfJVM);

# JVM SAYISI 0 DAN BUYUK OLMALI #
if( $numOfJVM eq ""){
	$numOfJVM = 0;
}

if ($numOfJVM == 0){
	print "\n!!! $server sunucusunda JVM sayisi $numOfJVM, otomasyon solandiriliyor!\n\n";
	print "********** ********** ********** ********** **********\n";
	print "********** ********** ********** ********** **********\n\n";
	exit;
}


### DB2 WLB OZELLIGI AKTIF EDILECEK .XML DOSYALARINI YAKALAMA ###
$FILES = `ssh -q $server grep -liR 'properties.db2.jcc' /ibm/servers | grep '.xml' | grep -v '.xml_'`;
my @XML_FILES = split('\n', $FILES);


### DB2 WLB OZELLIGI AKTIF EDILECEK SUNUCU BILGILERI ###
print "*** Islem Yapilacak Sunucu: $server \n";

foreach $FILE (@XML_FILES){
	
	chomp($FILE);
	
	### DOSYADA DB2 WLB OZELLIGI AKTIF ISE ISLEM YAPILMAMALI ###
	my $updatedWLBcontrol1 = `ssh -q $server cat $FILE | grep -q 'enableSysplexWLB="true"' && echo "true" || echo "false"`;
	my $updatedWLBcontrol2 = `ssh -q $server cat $FILE | grep -q 'enableSysplexWLB="true"' && echo "true" || echo "false"`;
	chomp($updatedWLBcontrol1);
	chomp($updatedWLBcontrol2);
	

	if($updatedWLBcontrol1 eq "true" && $updatedWLBcontrol2 eq "true"){
		print "\n** $server sunucusundaki $FILE dosyasinda DB2 WLB özelliği aktiftir!\n\n";
		next;
	}
	
	
	### GECISI YAPILACAK DOSYAYA AIT BILGILERIN ALINMASI ###
	$FILEPATH = `ssh -q $server dirname $FILE`;
	$dirNAME = `ssh -q $server basename "\$(dirname $FILE)"`;
	$filename = `ssh -q $server basename $FILE`;
	chomp($FILEPATH);
	chomp($dirNAME);
	chomp($filename);
	
	
	### DOSYADA WLB OZELLIGI AKTIF DEGILSE ###
	if($filename eq ""){
		print "\n!!! $server sunucusundaki $FILE dosyasında DB2 WLB özelliği aktif değildir!\n\n";
		next;
	}
	
	
	### WLB OZELLIGI AKTIF EDILECEK XML DOSYASINA AIT BILGILER ###
	print "--- Islem Yapilacak Dosya: $filename \n";
	print "--- Islem Yapilacak Directory: $dirNAME \n";
	print "--- Islem Yapilacak Dosyanın Lokasyonu: $FILEPATH \n";
	
	
	
	### YEDEK ALMA ###
	$backupDizin = "/ibm/backup/configureWLB/";

	# YEDEKLEME DIZINI YARATMA #
	print "\n--- $server sunucusunda $backupDizin dizini kontrol ediliyor...\n";
	my $backupDir = `ssh -q $server test -d $backupDizin && echo "true" || echo "false"`;
		chomp($backupDir);
		if($backupDir eq "true"){
			print "--- $server sunucusunda $backupDizin dizini bulunmaktadir.\n";
		}else{
			print "!!! $server sunucusunda $backupDizin dizini bulunmamaktadir.\n";
			print "--- $server sunucusunda $backupDizin dizini yaratiliyor.\n";
			my $mkdir = `ssh -q $server mkdir /ibm/backup`;
			my $mkdir2 = `ssh -q $server mkdir /ibm/backup/configureWLB`;
			my $mkdir4backup = `ssh -q $server mkdir $backupDizin`;
		}

	# YEDEKLEME ISLEMI #
	print "\n--- $FILE dosyasi $backupDizin dizinine yedeklenecektir...\n";
	my $copyFILE = `ssh -q $server cp $FILE $backupDizin`;
	my $testCopy = `ssh -q $server test -f $backupDizin/$filename && echo "true" || echo "false"`;
	chomp($testCopy);
	if($testCopy eq "true"){
		print "--- $FILE dosyasi $server sunucusunda yedeklenmiştir...\n";
	}else{
		print "!!! $server sunucusundaki $FILE dosyasi yedeklenemedi, otomasyon sonlandiriliyor!\n\n";
		print "********** ********** ********** ********** **********\n";
		print "********** ********** ********** ********** **********\n\n";
		exit;
	}



	### XML DOSYASINDAKI WLB PARAMETRELERINI DEGISTIRME ###

	## ISLEM YAPILACAK DOSYAYI KLUSYMANT1 SUNUCUSUNA AKTARMA ##
	print "\n--- $FILE dosyasi klusymant1 sunucusuna gonderiliyor...\n";
	my $copy2usyman = `scp -r $server:$FILE /usy/liberty/configureWLB/`;


	## XML DOSYASI KONFIGURASYON GUNCELLEME ADIMLARI ##

	# 1-) MEVCUT TAG LERE PARAMETRE EKLENMESI #
	
	print "\n--- $filename dosyasinda mevcut parametreler guncelleniyor...\n";
	my $before1 = '<properties.db2.jcc';
	my $after1 = '<properties.db2.jcc enableSysplexWLB="true"';

	
	if($updatedWLBcontrol1 eq "false"){
		my $cmdInsert1 = `sed -i 's/$before1/$after1/g' /usy/liberty/configureWLB/$filename`;
	}
	
	
	# 3-) XML DOSYASININ INDENTATION AMACLI FORMATLANMASI #
	print "\n--- $filename dosyasi XML formatina gore duzenleniyor...\n";
	my $CMD_formattingXML = `xmllint --format /usy/liberty/configureWLB/$filename >> /usy/liberty/configureWLB/modified/tmp_$filename`;
	my $CMD_control_DefaultXMLtag = `grep -q '?xml version="1.0"' /usy/liberty/configureWLB/$filename && echo "true" || echo "false"`;
	if( $CMD_control_DefaultXMLtag eq "false"){
		my $CMD_formatting_tmpXML = `xmllint --c14n /usy/liberty/configureWLB/modified/tmp_$filename >> /usy/liberty/configureWLB/modified/$filename`;
	} else{
		my $CMD_formatting_tmpXML = `cat /usy/liberty/configureWLB/modified/tmp_$filename >> /usy/liberty/configureWLB/modified/$filename`;
	}


	# 4-) FORMATLANAN XML DOSYASINDA DB2 WLB ÖZELLİĞİ KONTROLU #
	print "\n--- $filename dosyasinda aktif edilen DB2 WLB ozelliginin durumu kontrol ediliyor...\n";
	my $CMD_controlXML1 = `grep -q ' enableSysplexWLB="true"' /usy/liberty/configureWLB/modified/$filename && echo "true" || echo "false"`;
	my $CMD_controlXML2 = `grep -q ' enableSysplexWLB="true"' /usy/liberty/configureWLB/modified/$filename && echo "true" || echo "false"`;
	
	chomp($CMD_controlXML1);
	chomp($CMD_controlXML2);
	
	if($CMD_controlXML1 eq "true"){
		print "--- $filename dosyasında DB2 WLB ozelligi aktif edilmistir...\n";
	}else{
		print "!!! $filename dosyasında DB2 WLB ozelligi aktif edilememistir, otomasyon solandiriliyor!\n\n";
		print "********** ********** ********** ********** **********\n";
		print "********** ********** ********** ********** **********\n\n";
		exit;
		
	}	
	
	
	## GUNCELLENEN XML DOSYASINI SUNUCUYA AKTARMA ##
	print "\n--- $filename dosyasi $server sunucusuna gonderiliyor...\n";
	my $copy2server = `scp -r /usy/liberty/configureWLB/modified/$filename $server:$FILEPATH/`;
	
	
	## KLUSYMANT1 KALINTI TEMIZLEME ##
	print "\n--- klusymant1 sunucusunda kalıntılar temizleniyor...\n";
	my $clear = `find /usy/liberty/configureWLB/ -name "*.xml" -type f -delete`;
	
	
	print "\n--- $server sunucusunda $FILE icin islemler tamamlanmistir...\n\n";
	$jvmRestartFlag = 1;
	
	print "\n----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----\n\n";
	
}


## SUNUCU RESTART ##
if($jvmRestartFlag == 1){
	print "\n--- $server sunucusunda jvm restart islemi uygulaniyor...\n\n";
	my $stopCmd = " perl /ibm/wlp/bin/zeus.pl stop all";
	my $startCmd = " perl /ibm/wlp/bin/zeus.pl start all";
	my $restart = `ssh -q $server " $stopCmd && $startCmd "`;
}else{
	print "\n** $server sunucusunda DB2 baglantisi olmadigi icin degisiklik yapilmayacaktir...\n\n";
	
	print "\n** $server sunucusunda jvm restart islemi uygulanmayacaktir...\n\n";
}


print "********** ********** ********** ********** **********\n";
print "********** ********** ********** ********** **********\n\n";