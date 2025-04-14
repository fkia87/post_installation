#!/usr/bin/env bash
set -eo pipefail

: "${ram:=2048}"
: "${vcpus:=2}"
: "${size:=20G}"
: "${sound:=none}"
: "${uefi:=off}"

: "${SYM_LINK_DIR:=libvirt-images}"
: "${GET_IP_MAX_RETRIES:=50}"

print_help() {
    echo "Usage:"
    echo "  size=<int_gig> \\"
    echo "  ram=<int_meg> \\"
    echo "  vcpus=<int> \\"
    echo "  uefi=on|off \\"
    echo "  sound=none|default \\"
    echo "  cloudinit_file=/path/to/cloudinit.yml \\"
    echo "  virt-install.sh <qcow2_image_path> [vm_name]"
    echo
    echo "Default values:"
    echo "  size=$size"
    echo "  ram=$ram"
    echo "  vcpus=$vcpus"
    echo "  sound=$sound"
    echo "  uefi=$uefi"
    echo "  cloudinit_file=''"
    exit 0
}

[[ $1 == "-h" || $1 == "--help" || $# == 0 ]] && print_help

err() {
    echo -e "${RED}$1${DECOLOR}"
    exit 1
}

get_clinit_opt() {
    # --cloud-init defaults to: root-password-generate=on,disable=on
    if [[ -n $cloudinit_file ]]; then
        echo "user-data=$cloudinit_file"
    else
        echo "root-password-generate=on,disable=on"
    fi
}

check_commands() {
    # Exit if any of the given commands is not available
    for cmd in "$@"; do
        command -v "$cmd" > /dev/null 2>&1 || err "'$cmd' is not installed."
    done
}

get_vm_ip() {
    local max_retries=$GET_IP_MAX_RETRIES
    while : 
    do
        ipaddress=$(virsh domifaddr "$1" | tail -2 | head -1 | \
            awk '{print$4}' | cut -d '/' -f 1)
        [[ -n $ipaddress ]] && \
            { echo "$ipaddress"; break; }
        (( --max_retries )) || err "\nFailed to get the IP address."
        sleep 1
    done
}

[[ $UID == "0" ]] || err "You are not root."
[[ -n $cloudinit_file ]] && [[ ! -s $cloudinit_file ]] && \
    err "'$cloudinit_file' is not accessible."
check_commands virt-install virsh

file=$1
[[ -s $file ]] || err "'$file' is not accessible."
file_name=${file##*/}; file_name=${file_name:?Please enter QCOW2 file name.}
def_vm_name=${file_name%.qcow2}-$(od -An -N2 -tu < /dev/urandom | tr -d ' ')
vm_name=${2:-$def_vm_name}

[[ -L ./$SYM_LINK_DIR ]] || ln -s /var/lib/libvirt/images ./"$SYM_LINK_DIR"

echo -e "Copying image file to: './$SYM_LINK_DIR/$vm_name.qcow2'..."
cp "$file" "./$SYM_LINK_DIR/$vm_name.qcow2" && \
    echo "Resizing image..." && \
    qemu-img resize --shrink "./$SYM_LINK_DIR/$vm_name.qcow2" "$size" && \
    echo -e "Creating VM $vm_name..." && \
    virt-install -q \
        --name "$vm_name" \
        --memory "$ram" \
        --boot uefi="$uefi" \
        --cpu host-model --vcpus "$vcpus" \
        --osinfo detect=on,require=off \
        --disk "./$SYM_LINK_DIR/$vm_name.qcow2,format=qcow2,bus=virtio" \
        --sound "$sound" \
        --graphics spice,listen=none \
        --redirdev none \
        --network "network=default,model=virtio" \
        --cloud-init "$(get_clinit_opt)" \
        --noautoconsole && \
        # --noreboot
        # --graphics vnc,listen=0.0.0.0
    echo -e "${GREEN}VM created successfully.${DECOLOR}" && \
    echo -e "Waiting for IP address..." && \
    echo -e "VM IP: $(get_vm_ip "$vm_name")"
