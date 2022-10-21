#!/bin/bash

sudo sed -i '/^Storage=volatile/d' /etc/systemd/journald.conf
echo Storage=volatile | sudo tee -a /etc/systemd/journald.conf

echo "Restarting \"systemd-journald\" service..."
sudo systemctl restart systemd-journald

echo "Updating kernel parameters..."
sudo cp /etc/default/grub{,.bak}
sudo sed -i 's/^GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="pcie_aspm=off"/' /etc/default/grub
sudo update-grub

echo "Creating directories in \"$HOME\"..."
mkdir -p ~/{.fonts,.themes,bin,Applications,.icons,.ssh,.config/terminator}

if ! pacman -Q terminator; then
    echo -e "\nInstalling \"terminator\"\n"
    sudo pacman -Sy --noconfirm terminator
    cp ./configurations/terminator_config/config ~/.config/terminator
fi

echo "Configuring \"SSH\"..."
sudo cp /etc/ssh/ssh_config{,.bak}
cp -r ./configurations/ssh/* ~/.ssh
chmod 700 ~/.ssh; chmod 644 ~/.ssh/id_rsa.pub; chmod 600 ~/.ssh/id_rsa ~/.ssh/known_hosts
cat ./configurations/ssh_config | sudo tee -a /etc/ssh/ssh_config

if [[ "$DESKTOP_SESSION" == "xfce" ]]; then
	echo "Configuring \"XFCE\" terminal..."
	cp ./configurations/terminalrc ~/.config/xfce4/terminal/terminalrc
fi

cp ./scripts/* ~/bin/ && chmod +x ~/bin/*

echo "Configuring \"GoFlex\" auto mount..."
mkdir -p ~/GoFlex
sudo cp /etc/fstab{,.bak}
cat ./configurations/fstab | grep GoFlex | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
sudo mount -a

echo "Configuring VPN proxy services..."
sudo cp ./configurations/ag-proxy.service /etc/systemd/system
sudo cp ./configurations/evo-proxy.service /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable ag-proxy.service --now
sudo systemctl enable evo-proxy.service --now
