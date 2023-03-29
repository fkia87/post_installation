#!/bin/bash

echo "$(nvidia-smi -q |grep 'GPU Current Temp' | awk '{print $5}')"C / \
"$(sudo nvidia-smi -q | grep -i fan | awk '{print $4}')"%