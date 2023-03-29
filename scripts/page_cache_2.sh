#!/bin/bash
grep -i dirty /proc/meminfo | awk '{print$2,$3}'
