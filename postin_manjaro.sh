#!/bin/bash

source resources/os
source resources/bash_colors
source resources/pkg_management
source common

checkuser

strt_msg

get_target_user

config_journald

echo -e "${BLUE}\nUpdating kernel parameters...${DECOLOR}"
cp /etc/default/grub{,.bak}
sed -i 's/^GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="pcie_aspm=off"/' /etc/default/grub
update-grub 2>/dev/null

create_dirs

config_ssh

install_scripts

config_goflex

common_pkg

config_proxy

echo -e "${BLUE}\nConfiguring \"bashrc\"...${DECOLOR}"
cat ./configurations/bashrc-manjaro >> /etc/bash.bashrc

finish_msg