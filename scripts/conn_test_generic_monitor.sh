#!/bin/bash

[[ -z $1 ]] && { echo "Enter IP address"; exit 1; }

if ! eval "$(ping "$1" -c1 -W 5 | grep -o 'time=[0-9]*')"; then
	echo -e "$1 =/= N/A"
else
	# shellcheck disable=SC2154
	echo -e "$1 === $time ms"
fi
