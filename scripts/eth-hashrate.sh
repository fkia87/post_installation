#!/bin/bash
declare MH=""
while [[ $MH == "" ]]
do
	MH=$(curl -s https://api.nanopool.org/v1/eth/reportedhashrate/$1 |sed 's/.*data//'|cut -d ':' -f 2|cut -d '.' -f1)
done
echo $MH" Mh/s"
