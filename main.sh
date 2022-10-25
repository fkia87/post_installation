#!/bin/bash

git clone https://github.com/fkia87/resources.git || \
{echo -e "Error downloading required files from Github.
Check if \"Git\" is installed and your internet connection is OK." >&2; \
exit 1; }

source resources/os

[[ "$(os)" == "manjaro" ]] && ./postin_manjaro.sh
[[ "$(os)" == "fedora" ]] && ./postin_fedora.sh