#!/bin/bash

if ping -c1 -W1 google.com > /dev/null 2>&1; then
	echo "OK"
else
	echo "Failed"
fi
