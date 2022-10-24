#!/bin/bash

source resources/os
source resources/bash_colors
source resources/pkg_management
source common

checkuser

strt_msg

REL=$(cat /etc/fedora-release |awk {'print$3'})

get_target_user

config_journald

echo -e "${BLUE}\nUpdating kernel parameters...${DECOLOR}"
grubby --update-kernel ALL --args "selinux=0 pcie_aspm=off"

echo -e "${BLUE}Turning \"SELinux\" off...${DECOLOR}"
setenforce 0

create_dirs

echo -e "${BLUE}Writing configurations...${DECOLOR}"
cp ./configurations/dnf.conf /etc/dnf/dnf.conf

config_ssh

install_scripts

config_goflex

config_proxy

echo -e "${BLUE}Installing \"rpm fusion repositories\"...${DECOLOR}"
dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${REL}.noarch.rpm \
https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${REL}.noarch.rpm

common_pkg

echo -e "${BLUE}\nConfiguring \"bashrc\"...${DECOLOR}"
cat ./configurations/bashrc-fedora >> /etc/bashrc

finish_msg