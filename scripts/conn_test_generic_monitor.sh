#!/bin/bash

[[ -z $1 ]] && { echo "Enter IP address"; exit 1; }

if ! ping "$1" -W 0.5 -c 1 > /dev/null 2>&1; then
	echo -e "|$1 =/= OK|"
else
	echo -e "|$1 === OK|"
fi