#!/bin/bash
cd /usy/liberty_file_updater/
file=/usy/liberty_file_updater/input.bash

while IFS= read -r host_name
do
    host_trimmed="$(echo -e "$host_name" | tr -d '[[:space:]]')"
	array+=("$host_trimmed")
	
done < $file

for HOST in "${array[@]}"
do
	lib_file=0
	ssh_conn=0
	aux_file=0
	#echo -e "sunucular: ${array[@]} "
	echo -e "*******************************************"
	converted_hostname=`host $HOST | awk '{print $5}' | awk -F '.' '{print $1}'`  ### Bu satır ve altındaki satır input dosyasında dns veriliyorsa comment lenmeli. ip veriliyorsa kullanılmalı.
	HOST=$converted_hostname
	echo -e "islem yapilacak sunucu: $HOST"
	ssh_check=`ssh -q -o ConnectTimeout=30 $HOST cd /ibm` && ssh_conn=1 && echo -e "$HOST sunucusunun ssh baglantisinda bir problem yoktur." || echo -e "$HOST sunucusunun ssh baglantisi kontrol edilmelidir."
	if [ $ssh_conn -eq 1 ]
	then
		del_files1=`ssh -q $HOST rm -rf /ibm/old_wlp/*` && echo -e "log4j ile ilgili eski jarlar siliniyor."
		
		#send_files1=`scp /usy/liberty_file_updater/log4j_jars/log4j_2.17.2_jars/log4j* user@$HOST.domain:/ibm/old_wlp/wlp/templates/servers/*********/lib/AuxiliaryJars/` && echo -e "Yeni jarlar sunucuya gönderiliyor." || echo -e "Jarlar gonderilirken bir hata olustu."
				
		#del_files2=`ssh -q $HOST rm /ibm/wlp/templates/servers/*********/lib/AuxiliaryJars/log4j*` && echo -e "log4j ile ilgili eski jarlar siliniyor."

		#send_files2=`scp /usy/liberty_file_updater/log4j_jars/log4j_2.17.2_jars/log4j* user@$HOST.domain:/ibm/wlp/templates/servers/*********/lib/AuxiliaryJars/` && echo -e "Yeni jarlar sunucuya gönderiliyor." || echo -e "Jarlar gonderilirken bir hata olustu."		
				
	fi
	echo -e "Bu sunucu icin yapilan islemler tamamlanmistir."
	echo -e "************************************************\n\n\n"
done

