#!/bin/bash
declare TMP=""
while [[ $TMP == "" ]]
do
	TMP=$(curl -s https://slushpool.com/accounts/workers/json/btc/ -H "SlushPool-Auth-Token: 1qNztmgNuSRylfwm")
	UNIT=$(echo $TMP |cut -d , -f3|cut -d ':' -f 2|tr -d ' '| tr -d '"')
	TH=$(echo $TMP |cut -d , -f4|cut -d ':' -f 2|cut -d '.' -f1|tr -d ' ')
	sleep 8
done
echo $TH $UNIT
