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
		check_lib_file=`ssh -q $HOST find /ibm/servers/*/lib/` && lib_file=1 && echo -e "Paket sdf kullanip kullanmadigina dair kontroller yapiliyor. Sdf ile ilgili dosyalar güncellenecektir." || echo -e "Paket sdf kullanmadigi icin, sdf ile ilgili dosyalar degistirilmeyecektir."
		if [ $lib_file -eq 1 ]
		then
			check_aux_file=`ssh -q $HOST find /ibm/servers/*/lib/AuxiliaryJars/` && aux_file=1 && echo -e "Sunucudaki dizinlerde bir sorun görülememistir. Paket sdf kullanmaktadir." || echo -e "Sdf jarlarina ait dizinler bulunamamistir. Muhtemelen paket sdf kullanmiyor."
			if [ $aux_file -eq 1 ]
			then
		
			give_permission=`ssh -q $HOST chmod -R 755 /ibm/servers/*`
			
			echo -e "Dosyalara gereken permissionlar veriliyor."
			
			jvmnumber=`ssh -q $HOST ls /ibm/servers/ | wc -l`
			jvmnumber="$(echo -e "$jvmnumber" | tr -d '[[:space:]]')" ###trimming
			echo -e "Bu sunucudaki jvm sayisi: $jvmnumber"
			
			for ((i=1; i<=$jvmnumber; i++))
			do
				jvmname=`ssh -q $HOST ls /ibm/servers/ | head -n $i | tail -n 1`
				jvmname="$(echo -e "$jvmname" | tr -d '[[:space:]]')"
				echo -e "Islem yapilacak jvm: $jvmname"
				
				del_files=`ssh -q $HOST rm /ibm/servers/$jvmname/lib/AuxiliaryJars/log4j*` && echo -e "log4j ile ilgili eski jarlar siliniyor."

				send_files=`scp /usy/liberty_file_updater/log4j_jars/log4j_2.16_jars/log4j* wasadm@$HOST.isbank:/ibm/servers/$jvmname/lib/AuxiliaryJars/` && echo -e "Yeni jarlar sunucuya gönderiliyor." || echo -e "Jarlar gonderilirken bir hata olustu."


				# del_files2=`ssh -q $HOST rm /ibm/servers/$jvmname/lib/FrameworkJars/sdf-core*` && echo -e "sdf-core ile ilgili eski jarlar siliniyor."

				# send_files2=`scp /usy/liberty_file_updater/sdf-core_jars/2021-12-15/sdf-core* wasadm@$HOST.isbank:/ibm/servers/$jvmname/lib/FrameworkJars/` && echo -e "Yeni jarlar sunucuya gönderiliyor." || echo -e "Jarlar gonderilirken bir hata olustu."
			
			done
			

			
			###### Alias Kontrolu Yapılıp JVM'ler Restart Ediliyor. ########

			add_alias=`perl /usy/liberty/addAlias/addAlias4one.pl $HOST` && echo -e "alias kontrolleri yapiliyor."
			
			stop_jvms=`ssh -q $HOST /bin/bash -ic stopall` && echo -e "JVM ler stop ediliyor."
			
			start_jvms=`ssh -q $HOST /bin/bash -ic startall` && echo -e "JVM ler start edildi."
			fi
		fi
	fi
	echo -e "Bu sunucu icin yapilan islemler tamamlanmistir."
	echo -e "************************************************\n\n\n"
done

