#!/bin/bash

source resources/os
source resources/bash_colors
source resources/pkg_management

checkuser

echo -e "${BOLD}\n###### Starting post installation script for \"$(os)\" ######\n${DECOLOR}"

echo -e "${BLUE}\nEnter your target Linux username:${DECOLOR}"
read TARGETUSER

echo -e "${BLUE}\nConfiguring \"journald\"...${DECOLOR}"
sed -i '/^Storage=volatile/d' /etc/systemd/journald.conf
echo -e "Storage=volatile" >> /etc/systemd/journald.conf
systemctl restart systemd-journald

echo -e "${BLUE}\nUpdating kernel parameters...${DECOLOR}"
cp /etc/default/grub{,.bak}
sed -i 's/^GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="pcie_aspm=off"/' /etc/default/grub
update-grub > /dev/null

echo -e "${BLUE}\nCreating directories in \"$HOME\"...${DECOLOR}"
install -d -o fkia -g fkia /home/${TARGETUSER}\
/{.fonts,.themes,bin,Applications,.icons,.ssh}

echo -e "${BLUE}\nConfiguring \"SSH\"...${DECOLOR}"
cp /etc/ssh/ssh_config{,.bak}
install -o $TARGETUSER -g $TARGETUSER ./configurations/ssh/* /home/${TARGETUSER}/.ssh
chmod 700 /home/${TARGETUSER}/.ssh
chmod 644 /home/${TARGETUSER}/.ssh/id_rsa.pub
chmod 600 /home/${TARGETUSER}/.ssh/id_rsa
cat ./configurations/ssh_config >> /etc/ssh/ssh_config

echo -e "${BLUE}\nInstalling scripts...${DECOLOR}"
install -m 755 -o $TARGETUSER -g $TARGETUSER ./scripts/* /home/${TARGETUSER}/bin/

echo -e "${BLUE}\nConfiguring \"GoFlex\" auto mount...${DECOLOR}"
install -d -o fkia -g fkia /home/${TARGETUSER}/GoFlex
cp /etc/fstab{,.bak}
cat configurations/fstab >> /etc/fstab
systemctl daemon-reload
mount -a

install_pkg lsd
install_pkg duf

echo -e "${BLUE}\nConfiguring VPN proxy services...${DECOLOR}"
cp ./configurations/ag-proxy.service /etc/systemd/system/
cp ./configurations/evo-proxy.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable ag-proxy.service --now >/dev/null && \
echo -e "${GREEN}\nStarted \"ag-proxy\" service successfully.${DECOLOR}"
systemctl enable evo-proxy.service --now >/dev/null && \
echo -e "${GREEN}\nStarted \"evo-proxy\" service successfully.${DECOLOR}"

echo -e "${BLUE}\nConfiguring \"bashrc\"...${DECOLOR}"
cat ./configurations/bashrc-manjaro >> /etc/bash.bashrc && source /etc/bash.bashrc

echo -e "${GREEN}\nFinished configuring system.
It's recommended to restart your computer.${DECOLOR}"