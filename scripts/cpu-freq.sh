#!/bin/bash

grep -i 'mhz' /proc/cpuinfo |cut -d : -f2 |sed 's/.\{4\}$//'
