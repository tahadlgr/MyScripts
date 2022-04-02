#!/bin/bash
cd /usy/jvmcheck
. ./jvm_kurulu_sunucular.bash

HOSTS=$(python data.py)
#echo -e "$HOSTS \n\n"
#HOSTS=$(perl envanter.pl)

FILE_PATH='/ibm/servers'
>/usy/jvmcheck/jvm_kurulmamis_sunucular.bash

#arr1=( $HOSTS )
arr=( $variable )
k=0

for HOST in $HOSTS
do
	if [[ ! " ${arr[@]} " =~ " ${HOST} " ]]
	then
		cat /home/wasadm/.ssh/known_hosts | grep "$HOST " >/dev/null || ssh-keyscan -t ecdsa -T 60 $HOST >> /home/wasadm/.ssh/known_hosts  #ilk kez ssh atılan sunucular yes/no sormasın diye otomatik ekleniyor.
		fetch_domain=`nslookup $HOST | grep -A0 'Name' | awk '{print $2}'` #fetchind hostname and domain
		host_domain="$(echo -e "$fetch_domain" | tr -d '[[:space:]]')" #trimming
		cat /home/wasadm/.ssh/known_hosts | grep "$host_domain" >/dev/null || ssh-keyscan -t ecdsa -T 60 $HOST.isbank >> /home/wasadm/.ssh/known_hosts
		ssh -q $HOST [[ -e $FILE_PATH ]] && echo -e "$HOST sunucusunda $FILE_PATH dizini bulunmaktadir. \n" && k=1 || echo -e "$HOST sunucusunda $FILE_PATH dizini bulunamamistir. \n"

		if [ $k -eq 1 ]
		then
			jvm_options=`ssh -q $HOST find $FILE_PATH/*/jvm.options` && echo -e "jvm.options dosyası mevcuttur. Bu sunucuda JVM kuruludur. \n" && k=2 || echo -e "Bu sunucuda JVM kurulu degildir. \n"
			if [ $k -eq 2 ]
			then
				
				jvmnames=`ssh -q $HOST ls $FILE_PATH`
				echo -e "Kurulu JVM isimleri: $jvmnames \n"
				echo -e "$HOST sunucusu JVM kurulu sunucular listesine ekleniyor. \n"
				sed -i "3s/$/\n$HOST/" /usy/jvmcheck/jvm_kurulu_sunucular.bash
			else
				echo -e "Bu sunucuya jvm kurulmalıdır. $HOST sunucusu JVM kurulacak sunucular listesine ekleniyor. \n"
				echo -e "$HOST">>/usy/jvmcheck/jvm_kurulmamis_sunucular.bash
			fi
		else
			ssh -q $HOST mkdir /ibm/servers && echo -e "/ibm/servers dizini oluşturulmuştur. \n"
			echo -e "$HOST">>/usy/jvmcheck/jvm_kurulmamis_sunucular.bash
			
			##jvm_create=`ssh -q $HOST /ibm/wlp/bin/server create JVMNAME --template=isbankSdfProfile`
		fi
		
	else
		echo -e "$HOST sunucusu JVM kurulu sunucular listesindedir.\n"
	fi
done


