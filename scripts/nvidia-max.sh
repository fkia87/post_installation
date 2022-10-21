#!/bin/bash

#Puts NVIDIA GPU on maximum performance mode

nvidia-settings -a [gpu:0]/GpuPowerMizerMode=1 > /dev/null 2>&1
