#!/bin/bash

while :
do
	declare -i CONSTAT=`nmcli connection show Internet\ \(L2TP\) |grep VPN.VPN-STATE | awk '{print $2}'`
	if [ $CONSTAT != 5 ]
	then
		nmcli connection up Internet\ \(L2TP\) > /dev/null
		sudo systemctl restart tor
	fi
	sleep 300
done
