#!/bin/bash
declare -i x=`cat /proc/meminfo |grep -i dirty|awk {'print $2'}`
y=`echo -e "scale=2; $x/1000" | bc -q`
echo $y MB
