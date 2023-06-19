#!/bin/bash

declare -r RED='\033[0;31m'
declare -r DECOLOR='\033[0m'
declare -r YELLOW='\033[0;33m'
declare -r GREEN='\033[0;32m'
trap 'exit 2' SIGINT
[[ -z $1 ]] && { echo "Enter address to ping."; exit 1; }

while :; do
	if ! ping "$1" -W 0.5 -c 1 > /dev/null 2>&1; then
		time=$(date +%T)
		echo -e "($time)${YELLOW} $HOSTNAME ---> $1: ${RED}Connection lost!${DECOLOR}"
	else
		time=$(date +%T)
		echo -e "($time) $HOSTNAME ---> $1: ${GREEN}OK${DECOLOR}"
	fi
	sleep .5
done
