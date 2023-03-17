#!/bin/bash

files=("resources/pkg_management" "resources/os" "resources/bash_colors")
if ! [[ -f ${files[0]} ]] \
|| ! [[ -f ${files[1]} ]] \
|| ! [[ -f ${files[2]} ]]; then
    rm -rf resources
    git clone https://github.com/fkia87/resources.git || \
    { echo -e "Error downloading required files from Github.
Check if \"Git\" is installed and your internet connection is OK." >&2; \
    exit 1; }
fi
for file in ${files[@]}; do
    source $file
done
source common

checkuser

strt_msg

[[ "$(os)" == "fedora" ]] && REL=$(cat /etc/fedora-release | awk {'print$3'})

get_target_user

config_journald

case $(os) in
fedora)
    echo -e "${BLUE}\nUpdating kernel parameters...${DECOLOR}"
    grubby --update-kernel ALL --args "selinux=0 pcie_aspm=off"
    echo -e "${BLUE}Turning \"SELinux\" off...${DECOLOR}"
    setenforce 0
    ;;
manjaro)
    echo -e "${BLUE}\nUpdating kernel parameters...${DECOLOR}"
    cp /etc/default/grub{,.bak}
    sed -i 's/^GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="pcie_aspm=off"/' /etc/default/grub
    update-grub 2>/dev/null
    ;;
esac

create_dirs

case $(os) in
fedora)
    echo -e "${BLUE}Writing \"DNF\" configurations...${DECOLOR}"
    cp ./configurations/dnf.conf /etc/dnf/dnf.conf
    echo -e "${BLUE}Installing \"rpm fusion repositories\"...${DECOLOR}"
    dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${REL}.noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${REL}.noarch.rpm
    BASHRC="/etc/bashrc"
    ;;
esac

case $(os) in
fedora|manjaro)
    config_ssh
    install_scripts
    config_goflex
    [[ $? == 2 ]] && echo -e "${RED}\"GoFlex\" hard disk not found.${DECOLOR}"
    config_proxy
    common_pkg
    ;;
esac

case $(os) in
manjaro|ubuntu)
    BASHRC="/etc/bash.bashrc"
    ;;
esac

echo -e "${BLUE}\nConfiguring \"bashrc\"...${DECOLOR}"
sed -i '/^alias ll/d' /home/$TARGETUSER/.bashrc
cat ./configurations/bashrc-{$(os),common} >> $BASHRC

finish_msg