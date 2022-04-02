#!/usr/bin/perl

open my $fh, '>', '/usy/jvmcheck/logs/createdJvms.txt';

my $cmd = `/opt/rh/rh-python36/root/usr/bin/python /usy/jvmcheck/autoJvmCreate.py > /usy/jvmcheck/logs/autoJvmCreate.log 2>&1`;
my $alert = `cat /usy/jvmcheck/logs/createdJvms.txt`;


`echo 'Merhaba, \n\nSon taramada PROD ortamında en güncel imaja göre JVM kurulan sunucuların listesi şu şekildedir:\n\n$alert \n\nBu e-posta bilgilendirme amacıyla otomatik olarak atılmıştır. \nEn son yapılan kontrol ile ilgili bilgileri "/usy/jvmcheck/logs/autoJvmCreate.log" dosyasından bulabilirsiniz.' | mailx -S smtp=mail_address:Port -s "PROD ortamında JVM Kurulan Sunucular" -r mail_address\@isbank.com.tr -v mail_address\@isbank.com.tr`;

