#!/bin/bash

DEF_RAM=4096
DEF_VCPUS=4
DEF_SIZE=20G
DEF_CLINIT=./cloudinit-config.yml

[[ $1 == "-h" || $1 == "--help" ]] && \
    { 
        echo "Usage:";
        echo -n "[size=<disk_size>] [ram=<ram_megabytes>] [vcpus=<number>] ";
        echo "[cloudinit=<cloudinit_path>] virt-install.sh <qcow2_image_path> [vm_name]"
        echo -e "\nDefault values:\nsize=$DEF_SIZE\nram=$DEF_RAM\nvcpus=$DEF_VCPUS\ncloudinit=$DEF_CLINIT"
        exit 0; 
    }

file=${1##*/}; file=${file:?Please enter QCOW2 file name.}
symlinkdir=libvirt-images
def_vm_name=${file%.qcow2}-$(od -An -N2 -tu < /dev/urandom | tr -d ' ')

[[ $UID == "0" ]] || { echo "You are not root."; exit 1; }
[[ -s ./cloudinit-config.yml ]] || { echo "\"./cloudinit-config.yml\" is not accessible."; exit 1; }
[[ -L ./$symlinkdir ]] || ln -s /var/lib/libvirt/images ./$symlinkdir
[[ -s $1 ]] || { echo "\"$1\" is not accessible."; exit 1; }

virt-install --version > /dev/null 2>&1 || { echo "\"virt-install\" is not installed."; exit 1; }

cp "$file" ./$symlinkdir/"${2:-$def_vm_name}".qcow2 && \
qemu-img resize ./$symlinkdir/"${2:-$def_vm_name}".qcow2 "${size:-$DEF_SIZE}"

virt-install \
    --name "${2:-$def_vm_name}" \
    --memory "${ram:-$DEF_RAM}" \
    # --boot uefi \
    --cpu host-model --vcpus "${vcpus:-$DEF_VCPUS}" \
    --osinfo detect=on,require=off \
    --disk "./$symlinkdir/${2:-$def_vm_name}.qcow2,format=qcow2,bus=virtio" \
    --sound none \
    --graphics vnc,listen=0.0.0.0 \
    --redirdev none \
    --network "network=default,model=virtio" \
    --cloud-init user-data=${cloudinit:-$DEF_CLINIT} \
    --noautoconsole \
    # --noreboot
