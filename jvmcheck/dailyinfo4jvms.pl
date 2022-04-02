#!/usr/bin/perl

my $cmd = `bash /usy/jvmcheck/jvm_check.bash > /usy/jvmcheck/logs/jvm_check.log`;
my $alert = `cat /usy/jvmcheck/jvm_kurulmamis_sunucular.bash`;


`echo 'Merhaba, \n\nPROD ortamında JVM kurulu olmayan sunucuların listesi şu şekildedir:\n\n$alert \n\nBu e-posta bilgilendirme amacıyla otomatik olarak atılmıştır. \nEn son yapılan kontrol ile ilgili bilgileri "/usy/jvmcheck/logs/jvm_check.log" dosyasından bulabilirsiniz.' | mailx -S smtp=mail_address:Port -s "PROD ortamında JVM Kurulu Olmayan Sunucular" -r mail_address\@isbank.com.tr -v mail_address\@isbank.com.tr`;


