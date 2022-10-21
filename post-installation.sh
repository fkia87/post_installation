#!/bin/bash

REL=$(cat /etc/fedora-release |awk {'print$3'})

sudo sed -i '/^Storage=volatile/d' /etc/systemd/journald.conf
echo Storage=volatile | sudo tee -a /etc/systemd/journald.conf

echo "Restarting \"systemd-journald\" service..."
sudo systemctl restart systemd-journald

echo "Updating kernel parameters..."
sudo grubby --update-kernel ALL --args "selinux=0 pcie_aspm=off"

echo "Turning \"SELinux\" off..."
sudo setenforce 0

echo "Creating directories in \"$HOME\"..."
mkdir -p ~/{.fonts,.themes,bin,Applications,.icons,.ssh,terminator}

echo "Writing configurations..."; sleep 1
sudo cp ./configurations/dnf.conf /etc/dnf/dnf.conf
cp ./configurations/terminator_config/config ~/.config/terminator
#sudo cp /etc/default/grub{,.bak}
#sudo sed -i '/^GRUB_CMDLINE_LINUX/ s/\(.\)$/ pcie_aspm=off\1/' /etc/default/grub
#sudo grub2-mkconfig -o /boot/grub2/grub.cfg

echo "Configuring \"SSH\"..."
sudo cp /etc/ssh/ssh_config{,.bak}
cp -r ./configurations/ssh/* ~/.ssh
chmod 700 ~/.ssh; chmod 644 ~/.ssh/id_rsa.pub; chmod 600 ~/.ssh/id_rsa ~/.ssh/known_hosts
cat ./configurations/ssh_config | sudo tee -a /etc/ssh/ssh_config

if [ -f ~/.config/xfce4/terminal/terminalrc ]; then
	echo "Configuring \"XFCE\" terminal..."
	cp ./configurations/terminalrc ~/.config/xfce4/terminal/terminalrc
fi

cp ./scripts/* ~/bin/ && chmod +x ~/bin/*

if [ -d ~/.config/xfce4/panel/ ]; then
	echo "Configuring \"XFCE\" panels..."
	\cp -r ./configurations/xfce_panel_config/* ~/.config/xfce4/panel/
	\cp ./configurations/xfce4-keyboard-shortcuts.xml ~/.config/xfce4/xfconf/xfce-perchannel-xml/
fi

echo "Configuring \"GoFlex\" auto mount..."
mkdir -p ~/GoFlex
sudo cp /etc/fstab{,.bak}
cat ./configurations/fstab | grep GoFlex | sudo tee -a /etc/fstab
sudo mount -a

echo "Configuring VPN proxy services..."
sudo cp ./configurations/ag-proxy.service /etc/systemd/system
sudo cp ./configurations/evo-proxy.service /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable ag-proxy.service --now
sudo systemctl enable evo-proxy.service --now

echo "Removing unused packages..."
sudo dnf -q -y remove dnfdragora-* claws-mail-* pidgin-* geany-* parole-*.x86_64 xfburn-* mousepad-* xarchiver-* gnumeric-* ristretto-* transmission-* asunder-* abiword-* cheese eog gnome-photos totem
sudo dnf -q -y remove dnfdragora-* claws-mail-* pidgin-* geany-* parole-*.x86_64 xfburn-* mousepad-* xarchiver-* gnumeric-* ristretto-* transmission-* asunder-* abiword-* cheese eog gnome-photos totem

echo "Installing useful packages..."
sudo dnf -q -y install unar kernel-devel gedit gthumb libreoffice numix-icon-theme-circle nextcloud-client file-roller \
https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${REL}.noarch.rpm vim-syntastic-sh libgnome-keyring \
uget https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${REL}.noarch.rpm
sudo dnf -q -y install vlc terminator unrar

#echo "Installing \"passwordsafe\" software..."
#sudo dnf -q -y localinstall sw/passwordsafe-fedora*.rpm

echo "Upgrading system...";
while ! sudo dnf -y update; do
	echo "Upgrade unsuccessful"
	sleep 1
done

echo "Configuring \"bashrc\"..."
cp ./configurations/bashrc ~/.bashrc && . ~/.bashrc
