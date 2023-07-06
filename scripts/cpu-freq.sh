#!/bin/bash

grep -i 'mhz' /proc/cpuinfo | awk -F ': ' '{print$2}' | awk -F '.' '{print$1" MHz"}'