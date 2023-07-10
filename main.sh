#!/bin/bash
# shellcheck disable=SC2068,SC1091,SC1090,SC2154

# IMPORT REQUIREMENTS ############################################################################################
requirements=("resources/bash_colors" "resources/utils")
for ((i=0; i<${#requirements[@]}; i++)); do
    if ! [[ -d resources ]] || ! [[ -f ${requirements[i]} ]]; then
        rm -rf resources
        wget https://github.com/fkia87/resources/archive/refs/heads/master.zip || \
        { echo -e "Error downloading required files from Github." >&2; exit 1; }
        unzip master.zip || { echo -e "Command \"unzip master.zip\" failed." >&2; exit 1; }
        rm -f master.zip
        mv resources* resources
        break
    fi
done

for file in ${requirements[@]}; do
    source "$file"
done

##################################################################################################################
source ./common
checkuser
strt_msg
case "$(os)" in
    fedora | alma* | rocky*)
        REL=$(awk '{print$3}' < /etc/"$(os)"-release)
        ;;
esac
get_target_user
ask "Remove password for sudoers?" "passwordless_sudo"
config_journald

## GRUB ##########################################################################################################
case $(os) in
    fedora)
        echo -e "${BLUE}\nUpdating kernel parameters...${DECOLOR}"
        grubby --update-kernel ALL --args "selinux=0 pcie_aspm=off"
        echo -e "${BLUE}Turning \"SELinux\" off...${DECOLOR}"
        setenforce 0
        ;;
    manjaro | ubuntu | debian)
        echo -e "${BLUE}\nUpdating kernel parameters...${DECOLOR}"
        cp /etc/default/grub{,.bak}
        sed -i 's/^GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="pcie_aspm=off"/' /etc/default/grub
        update-grub 2>/dev/null
        ;;
esac

# Create directories #############################################################################################
create_dirs

## DNF ###########################################################################################################
case $(os) in
    fedora)
        echo -e "${BLUE}Writing \"DNF\" configurations...${DECOLOR}"
        cp ./configurations/dnf.conf /etc/dnf/dnf.conf
        echo -e "${BLUE}Installing \"rpm fusion repositories\"...${DECOLOR}"
        dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"${REL}".noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"${REL}".noarch.rpm
        ;;
esac

# Hosts, SSH and proxy configuration ####################################################################################
ask "Configure SSH tunnels?" "config_proxy" || ask "Setup SSH keys?" "config_ssh"
ask "Install \"/etc/hosts\"?" "config_hosts"

##################################################################################################################
install_scripts

# GoFlex #########################################################################################################
ask "Configure \"GoFlex\"?" "config_goflex"

# Package installation ###########################################################################################
case $(os) in
    fedora | manjaro)
        install_pkg lsd duf bat curl unrar
        ;;
    ubuntu | debian)
        install_pkg duf bat curl
        snap install lsd
        ;;
esac

# bachrc #########################################################################################################
echo -e "${BLUE}\nConfiguring \"bashrc\"...${DECOLOR}"
case $(os) in
    manjaro | ubuntu)
        BASHRC="/etc/bash.bashrc"
        ;;
    fedora | centos | almalinux | rocky)
        BASHRC="/etc/bashrc"
        ;;
esac
[[ $(os) == "ubuntu" ]] || sed -i '/^alias ll/d' "$targethome"/.bashrc
cat ./configurations/bashrc-{common,"$(os)"} >> "$BASHRC"

# Fonts ##########################################################################################################
ask "Do you want to install fonts?" "install_fonts"

##################################################################################################################
finish_msg