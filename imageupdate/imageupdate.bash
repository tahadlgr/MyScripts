#!/bin/bash

cd /usy/imageupdate

file=/usy/jvmcheck/jvm_kurulmamis_sunucular.bash
image_control_case=0

while IFS= read -r host_name
do
    host_trimmed="$(echo -e "$host_name" | tr -d '[[:space:]]')"
	array+=("$host_trimmed")
	
done < $file
#done < /usy/jvmcheck/jvm_kurulmamis_sunucular.bash


for host in "${array[@]}"
do
    echo "İslem yapılacak sunucu: $host"
	check_image=`ssh -q $host find /home/wasadm/updatedimage.txt` && echo -e "Bu sunucuda bulunan imaj günceldir. \n" && image_control_case=1 || echo -e "Bu sunucuda imaj güncel değildir. Imajın güncellenmesi gerekmektedir. \n"
	if [ $image_control_case -eq 0 ]
	then
		clean_old_images=`ssh -q $host rm -rf /ibm/old_wlp`
		cmd = `perl /usy/Atlas/upgradeWlp/upgradeWlp.pl $host`
		cmd2=`nslookup $host | grep -A0 'Name' | awk '{print $2}'` #fetchind hostname and domain for dmz exceptions
		host_domain="$(echo -e "$cmd2" | tr -d '[[:space:]]')" #trimming
		scp -q /usy/imageupdate/updatedimage.txt wasadm@$host_domain:/home/wasadm/
		echo -e "$host sunucusunda imaj güncellenmiştir. \n"
		add_alias=`perl /usy/liberty/addAlias/addAlias4one.pl $HOST` && echo -e "alias kontrolleri yapiliyor."
		
		
		del_files1=`ssh -q $HOST rm /ibm/old_wlp/wlp/templates/servers/isbankSdfProfile/lib/AuxiliaryJars/log4j*` && echo -e "log4j ile ilgili eski jarlar siliniyor."
		
		send_files1=`scp /usy/liberty_file_updater/log4j_jars/log4j_2.16_jars/log4j* wasadm@$HOST.isbank:/ibm/old_wlp/wlp/templates/servers/isbankSdfProfile/lib/AuxiliaryJars/` && echo -e "Yeni jarlar sunucuya gönderiliyor." || echo -e "Jarlar gonderilirken bir hata olustu."
				
		del_files2=`ssh -q $HOST rm /ibm/wlp/templates/servers/isbankSdfProfile/lib/AuxiliaryJars/log4j*` && echo -e "log4j ile ilgili eski jarlar siliniyor."

		send_files2=`scp /usy/liberty_file_updater/log4j_jars/log4j_2.16_jars/log4j* wasadm@$HOST.isbank:/ibm/wlp/templates/servers/isbankSdfProfile/lib/AuxiliaryJars/` && echo -e "Yeni jarlar sunucuya gönderiliyor." || echo -e "Jarlar gonderilirken bir hata olustu."		
				
		echo -e "************************************************************ \n\n"
	else
		echo -e "$host sunucusunda imaj güncel olduğu için işlem yapılmayacaktır. \n" && image_control_case=0
		echo -e "************************************************************ \n\n"
	fi
done


