#!/bin/bash
set -euo pipefail


# Global Variables:
###################################################################################################
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
DECOLOR='\033[0m'


# Functions:
###################################################################################################
err() {
    kill_children() {
        script_pid=$$
        child_pids=$(pgrep -P $script_pid 2> /dev/null || echo '')
        [ -n "$child_pids" ] && kill "$child_pids" 2> /dev/null
    }
    kill_children
    echo -e "${RED}$1${DECOLOR}" >&2
    exit 1
}


# Procedure:
###################################################################################################

