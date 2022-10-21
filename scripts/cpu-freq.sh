#!/bin/bash

cat /proc/cpuinfo |grep -i 'mhz' |cut -d : -f2 |sed 's/.\{4\}$//'
