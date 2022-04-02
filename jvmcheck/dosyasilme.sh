#!/bin/bash

HOSTS="

"

for HOST in $HOSTS
do
	del_file=`ssh -q $HOST rm /home/wasadm/updatedimage.txt`
	echo -e "$HOST sunucusunda txt dosyasi silindi."
done
