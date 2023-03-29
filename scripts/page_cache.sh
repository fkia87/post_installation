#!/bin/bash
declare -i x; x=$(grep -i dirty /proc/meminfo | awk '{print $2}')
y=$(echo -e "scale=2; $x/1000" | bc -q)
echo "$y" MB
