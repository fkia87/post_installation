#!/bin/bash

source resources/os
source resources/bash_colors

checkuser

echo -e "${BOLD}\n###### Starting post installation script for \"$(os)\" ######\n${DECOLOR}"

REL=$(cat /etc/fedora-release |awk {'print$3'})

echo -e "${BLUE}\nEnter your target Linux username:${DECOLOR}"
read TARGETUSER

echo -e "${BLUE}\nConfiguring \"journald\"...${DECOLOR}"
sed -i '/^Storage=volatile/d' /etc/systemd/journald.conf
echo -e "Storage=volatile" >> /etc/systemd/journald.conf
systemctl restart systemd-journald

echo -e "${BLUE}\nUpdating kernel parameters...${DECOLOR}"
grubby --update-kernel ALL --args "selinux=0 pcie_aspm=off"

echo -e "${BLUE}Turning \"SELinux\" off...$DECOLOR}"
setenforce 0

echo -e "${BLUE}\nCreating directories in \"$HOME\"...${DECOLOR}"
install -d -o fkia -g fkia /home/${TARGETUSER}\
/{.fonts,.themes,bin,Applications,.icons,.ssh}

echo -e "${BLUE}Writing configurations...${DECOLOR}"
cp ./configurations/dnf.conf /etc/dnf/dnf.conf

echo -e "${BLUE}Configuring \"SSH\"...${DECOLOR}"
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

echo -e "${BLUE}\nConfiguring VPN proxy services...${DECOLOR}"
cp ./configurations/ag-proxy.service /etc/systemd/system/
cp ./configurations/evo-proxy.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable ag-proxy.service --now && \
echo -e "${GREEN}\nStarted \"ag-proxy\" service successfully.${DECOLOR}"
systemctl enable evo-proxy.service --now && \
echo -e "${GREEN}\nStarted \"evo-proxy\" service successfully.${DECOLOR}"

echo -e "${BLUE}Removing unused packages...${DECOLOR}"
dnf -y remove dnfdragora-* claws-mail-* pidgin-* geany-* parole-*.x86_64 xfburn-* \
mousepad-* xarchiver-* gnumeric-* ristretto-* transmission-* asunder-* abiword-* cheese \
eog gnome-photos totem
dnf -y remove dnfdragora-* claws-mail-* pidgin-* geany-* parole-*.x86_64 xfburn-* \
mousepad-* xarchiver-* gnumeric-* ristretto-* transmission-* asunder-* abiword-* cheese \
eog gnome-photos totem

echo -e "${BLUE}Installing \"rpm fusion repositories\"...${DECOLOR}"
dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${REL}.noarch.rpm \
https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${REL}.noarch.rpm

echo -e "${BLUE}\nConfiguring \"bashrc\"...${DECOLOR}"
cat ./configurations/bashrc-fedora >> /etc/bashrc && source /etc/bashrc

echo -e "${GREEN}\nFinished configuring system.
It's recommended to restart your computer.${DECOLOR}"