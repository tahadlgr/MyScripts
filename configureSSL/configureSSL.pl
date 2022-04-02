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
my $JVMNAME;
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
	print "\n!!! $server sunucusunda JVM sayisi $numOfJVM, otomasyon sonlandiriliyor!\n\n";
	print "********** ********** ********** ********** **********\n";
	print "********** ********** ********** ********** **********\n\n";
	exit;
}


### SSL KONFIGURASYONU ICEREN .XML DOSYALARINI YAKALAMA ###
$FILES = `ssh -q $server grep -liR 'clientAuthenticationSupported' /ibm/servers | grep '.xml' | grep -v '.xml_'`;
my @XML_FILES = split('\n', $FILES);


### TLSv1.2 GUNCELLEMESI YAPILACAK SUNUCU BILGILERI ###
print "*** Islem Yapilacak Sunucu: $server \n";

foreach $FILE (@XML_FILES){
	
	chomp($FILE);
	
	### DOSYADA TLSv1.2 GECISI YAPILMISSA DOSYADA ISLEM YAPILMAMALI ###
	my $updatedSSLcontrol1 = `ssh -q $server cat $FILE | grep -q 'sslProtocol="TLSv1.2"' && echo "true" || echo "false"`;
	my $updatedSSLcontrol2 = `ssh -q $server cat $FILE | grep -q 'sslProtocol="TLSv1.2"' && echo "true" || echo "false"`;
	my $updatedSSLcontrol3 = `ssh -q $server cat $FILE | grep -q 'id="controllerConnectionConfig" sslProtocol="TLSv1.2"' && echo "true" || echo "false"`;
	my $updatedSSLcontrol4 = `ssh -q $server cat $FILE | grep -q 'id="memberConnectionConfig" sslProtocol="TLSv1.2"' && echo "true" || echo "false"`;
	chomp($updatedSSLcontrol1);
	chomp($updatedSSLcontrol2);
	chomp($updatedSSLcontrol3);
	chomp($updatedSSLcontrol4);

	if($updatedSSLcontrol1 eq "true" && $updatedSSLcontrol2 eq "true" && $updatedSSLcontrol3 eq "true" && $updatedSSLcontrol4 eq "true"){
		print "\n** $server sunucusundaki $FILE dosyasinda TLSv1.2 konfigurasyonu mevcuttur!\n\n";
		next;
	}
	
	
	### TLSv1.2 GECISI YAPILACAK DOSYAYA AIT BILGILERIN ALINMASI ###
	$FILEPATH = `ssh -q $server dirname $FILE`;
	$JVMNAME = `ssh -q $server basename "\$(dirname $FILE)"`;
	$filename = `ssh -q $server basename $FILE`;
	chomp($FILEPATH);
	chomp($JVMNAME);
	chomp($filename);
	
	
	### DOSYA SSL KONFIGURAYONLARI ICERMIYORSA ###
	if($filename eq ""){
		print "\n!!! $server sunucusundaki $FILE dosyasında SSL konfigürasyonu bulunmamaktadir!\n\n";
		next;
	}
	
	
	### TLSv1.2 GECISI YAPILACAK XML DOSYASINA AIT BILGILER ###
	print "--- Islem Yapilacak Dosya: $filename \n";
	print "--- Islem Yapilacak JVM: $JVMNAME \n";
	print "--- Islem Yapilacak Dosyanın Lokasyonu: $FILEPATH \n";
	
	
	
	### YEDEK ALMA ###
	$backupDizin = "/ibm/backup/configureSSL/$JVMNAME/";

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
			my $mkdir2 = `ssh -q $server mkdir /ibm/backup/configureSSL`;
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
		print "!!! $server sunucusundaki $FILE dosyasi yedeklenemedi, otomasyon solandiriliyor!\n\n";
		print "********** ********** ********** ********** **********\n";
		print "********** ********** ********** ********** **********\n\n";
		exit;
	}



	### XML DOSYASINDAKI SSL PARAMETRELIRINI DEGISTIRME ###

	## ISLEM YAPILACAK DOSYAYI KLUSYMANT1 SUNUCUSUNA AKTARMA ##
	print "\n--- $FILE dosyasi klusymant1 sunucusuna gonderiliyor...\n";
	my $copy2usyman = `scp -r $server:$FILE /usy/liberty/configureSSL/`;


	## XML DOSYASI KONFIGURASYON GUNCELLEME ADIMLARI ##

	# 1-) MEVCUT TAG LERE PARAMETRE EKLENMESI #
	print "\n--- $filename dosyasinda mevcut parametreler guncelleniyor...\n";
	my $before1 = 'keyStoreRef="defaultKeyStore"';
	my $after1 = 'keyStoreRef="defaultKeyStore" sslProtocol="TLSv1.2"';

	my $before2 = 'keyStoreRef="httpKeyStore"';
	my $after2 = 'keyStoreRef="httpKeyStore" sslProtocol="TLSv1.2"';

	if($updatedSSLcontrol1 eq "false"){
		my $cmdInsert1 = `sed -i 's/$before1/$after1/g' /usy/liberty/configureSSL/$filename`;
	}
	if($updatedSSLcontrol2 eq "false"){
		my $cmdInsert2 = `sed -i 's/$before2/$after2/g' /usy/liberty/configureSSL/$filename`;
	}
	

	# 2-) YENI PARAMETRE SATIRLARIIN EKLENMESI #
	print "\n--- $filename dosyasina yeni parametreler ekleniyor...\n";
	my $addAfter1 = "sslDefault sslRef=\"defaultSSLSettings\"";
	my $newline1 = "<ssl id=\"memberConnectionConfig\" sslProtocol=\"TLSv1.2\"/>";

	my $addAfter2 = "sslDefault sslRef=\"defaultSSLSettings\"";
	my $newline2 = "<ssl id=\"controllerConnectionConfig\" sslProtocol=\"TLSv1.2\"/>";

	if($updatedSSLcontrol3 eq "false"){
		my $cmdAdd1 = `sed -i '/$addAfter1/a $newline1' /usy/liberty/configureSSL/$filename`; 
	}

	if($updatedSSLcontrol4 eq "false"){
		my $cmdAdd2 = `sed -i '/$addAfter2/a $newline2' /usy/liberty/configureSSL/$filename`;
	}


	# 3-) XML DOSYASININ INDENTATION AMACLI FORMATLANMASI #
	print "\n--- $filename dosyasi XML formatina gore duzenleniyor...\n";
	my $CMD_formattingXML = `xmllint --format /usy/liberty/configureSSL/$filename >> /usy/liberty/configureSSL/modified/tmp_$filename`;
	my $CMD_control_DefaultXMLtag = `grep -q '?xml version="1.0"' /usy/liberty/configureSSL/$filename && echo "true" || echo "false"`;
	if( $CMD_control_DefaultXMLtag eq "false"){
		my $CMD_formatting_tmpXML = `xmllint --c14n /usy/liberty/configureSSL/modified/tmp_$filename >> /usy/liberty/configureSSL/modified/$filename`;
	} else{
		my $CMD_formatting_tmpXML = `cat /usy/liberty/configureSSL/modified/tmp_$filename >> /usy/liberty/configureSSL/modified/$filename`;
	}


	# 4-) FORMATLANAN XML DOSYASINDA TLSv1.2 KONFIGURASYON KONTROLU #
	print "\n--- $filename dosyasinda uygulanan TLSv1.2 konfigurasyonlarinin durumu kontrol ediliyor...\n";
	my $CMD_controlXML1 = `grep -q 'keyStoreRef="defaultKeyStore" sslProtocol="TLSv1.2"' /usy/liberty/configureSSL/modified/$filename && echo "true" || echo "false"`;
	my $CMD_controlXML2 = `grep -q 'keyStoreRef="httpKeyStore" sslProtocol="TLSv1.2"' /usy/liberty/configureSSL/modified/$filename && echo "true" || echo "false"`;
	my $CMD_controlXML3 = `grep -q 'id="controllerConnectionConfig" sslProtocol="TLSv1.2"' /usy/liberty/configureSSL/modified/$filename && echo "true" || echo "false"`;
	my $CMD_controlXML4 = `grep -q 'id="memberConnectionConfig" sslProtocol="TLSv1.2"' /usy/liberty/configureSSL/modified/$filename && echo "true" || echo "false"`;
	chomp($CMD_controlXML1);
	chomp($CMD_controlXML2);
	chomp($CMD_controlXML3);
	chomp($CMD_controlXML4);

	if($CMD_controlXML1 eq "true" && $CMD_controlXML2 eq "true" && $CMD_controlXML3 eq "true" && $CMD_controlXML4 eq "true"){
		print "--- $filename dosyasında TLSv1.2 konfigurasyonlari uygulanmistir...\n";
	}else{
		print "!!! $filename dosyasında TLSv1.2 konfigurasyonlari uygulanamamistir, otomasyon solandiriliyor!\n\n";
		print "********** ********** ********** ********** **********\n";
		print "********** ********** ********** ********** **********\n\n";
		exit;
	}	
	
	
	## GUNCELLENEN XML DOSYASINI SUNUCUYA AKTARMA ##
	print "\n--- $filename dosyasi $server sunucusuna gonderiliyor...\n";
	my $copy2server = `scp -r /usy/liberty/configureSSL/modified/$filename $server:$FILEPATH/`;
	
	
	## KLUSYMANT1 KALINTI TEMIZLEME ##
	print "\n--- klusymant1 sunucusunda kalıntılar temizleniyor...\n";
	my $clear = `find /usy/liberty/configureSSL/ -name "*.xml" -type f -delete`;
	
	
	print "\n--- $server sunucusunda $FILEPATH icin islemler tamamlanmistir...\n\n";
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
	print "\n** $server sunucusunda jvm restart islemi uygulanmayacaktir...\n\n";
}


print "********** ********** ********** ********** **********\n";
print "********** ********** ********** ********** **********\n\n";