#!/usr/bin/env bash
set -euo pipefail

filename=${1}.qcow2
vm_file="/var/lib/libvirt/images/$filename"

# Functions:
###################################################################################################
print_help() {
    echo -e "Export a VM as 'qcow2' image.\n"
    echo "Usage:"
    echo "  ${0##*/} <vm_name>"
    exit 0
}


err() {
    echo -e "${RED}$1${DECOLOR}"
    exit 1
}

check_commands() {
    # Exit if any of the given commands is not available
    for cmd in "$@"; do
        command -v "$cmd" > /dev/null 2>&1 || err "'$cmd' is not installed."
    done
}

check_vm_is_shutoff() {
    if [[ $(virsh domstate "$1") != "shut off" ]]; then
        err "Turn off the VM first."
    fi
}

# Procedure:
###################################################################################################
[[ $1 == "-h" || $1 == "--help" || $# == 0 ]] && print_help

## Prechecks
[[ $UID == "0" ]] || err "You are not root."
check_commands qemu-img virt-sysprep virsh
check_vm_is_shutoff "$1"

## Main
echo -e "Copying image to /tmp/..."
cp "$vm_file" /tmp/

echo -e "Running virt-sysprep..."
virt-sysprep -a /tmp/"$filename"

echo -e "Compressing image..."
qemu-img convert -c -f qcow2 -O qcow2 /tmp/"$filename" ./"$filename" && \
    echo -e "${GREEN}Wrote image to: ./$filename${DECOLOR}"

echo -e "Cleaning temporary files..."
rm -f /tmp/"$filename"
echo -e "Export finished. You may now remove the VM."
