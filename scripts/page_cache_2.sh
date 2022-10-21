#!/bin/bash
cat /proc/meminfo |grep -i dirty | awk {'print$2,$3'}
