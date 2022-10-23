#!/bin/bash

source resources/os

[[ "$(os)" == "manjaro" ]] && ./postin_manjaro.sh
[[ "$(os)" == "fedora" ]] && ./postin_fedora.sh