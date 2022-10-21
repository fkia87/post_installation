#!/bin/bash

gpu_util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader)
memory_used=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
memory_total=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)
gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader)
gpu_fan=$(nvidia-smi --query-gpu=fan.speed --format=csv,noheader)
memory_percent=$(echo "scale=1; ${memory_used}*100/${memory_total}" | bc)

echo G: $gpu_util
echo M: $memory_percent %
echo -e T: $gpu_temp "\u00b0"C
echo F: $gpu_fan