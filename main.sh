#!/bin/bash

rm -rf resources

git clone https://github.com/fkia87/resources.git || \
{ echo -e "Error downloading required files from Github.
Check if \"Git\" is installed and your internet connection is OK." >&2; \
exit 1; }

source resources/os
source resources/bash_colors
source resources/pkg_management
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
    ;;
esac

config_ssh

install_scripts

config_goflex

[[ "$(os)" == "manjaro" ]] && common_pkg

config_proxy

case $(os) in
fedora)
    echo -e "${BLUE}Installing \"rpm fusion repositories\"...${DECOLOR}"
    dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${REL}.noarch.rpm \
https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${REL}.noarch.rpm
    ;;
esac

[[ "$(os)" == "fedora" ]] && common_pkg

case $(os) in
fedora)
    echo -e "${BLUE}\nConfiguring \"bashrc\"...${DECOLOR}"
    cat ./configurations/bashrc-fedora >> /etc/bashrc
    ;;
manjaro)
    echo -e "${BLUE}\nConfiguring \"bashrc\"...${DECOLOR}"
    cat ./configurations/bashrc-manjaro >> /etc/bash.bashrc
    ;;
esac

finish_msg