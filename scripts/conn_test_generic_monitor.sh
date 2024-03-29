#!/bin/bash

[[ -z $1 ]] && { echo "Enter IP address"; exit 1; }

eval "$(ping "$1" -c1 -W 5 | grep -o 'time=[0-9]*')"
if [[ -n $time ]] ; then
	echo -e "$1 === $time ms"
else
	echo -e "$1 =||= N/A"
fi
