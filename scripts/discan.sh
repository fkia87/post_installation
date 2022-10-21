#!/bin/bash

typeset -i hostnumber=`ls -l /sys/class/scsi_host/ | wc -l`
hostnumber=hostnumber-1
for (( i=0; i<$hostnumber; i++ ))
do
  	echo "- - -" > /sys/class/scsi_host/host$i/scan
done
