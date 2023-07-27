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
ask "Config journald?" "config_journald"
ask "Set default scale for QT applications to 2?" "set_qt_scale_2"

## GRUB ##########################################################################################################
config_grub() {
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
}
ask "Grub configurations? (SELinux, pcie_aspm, ...)" "config_grub"

# Create directories #############################################################################################
create_dirs

## DNF ###########################################################################################################
case $(os) in
    fedora)
        config_dnf() {
            echo -e "${BLUE}Writing \"DNF\" configurations...${DECOLOR}"
            cp ./configurations/dnf.conf /etc/dnf/dnf.conf
            echo -e "${BLUE}Installing \"rpm fusion repositories\"...${DECOLOR}"
            dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"${REL}".noarch.rpm \
            https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"${REL}".noarch.rpm
        }
        ask "Config dnf and rpmfusion?" "config_dnf"
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
useful_packages() {
    case $(os) in
        fedora | manjaro)
            pkg_to_install+=(lsd unrar)
            ;;
        ubuntu | debian)
            snap install lsd
            ;;
    esac
    pkg_to_install+=(duf bat curl colorized-logs)
    install_pkg ${pkg_to_install[@]}
}
ask "Install usefule packages? (duf, bat, curl, ...)" "useful_packages"

# bachrc #########################################################################################################
echo -e "${BLUE}\nConfiguring \"bashrc\"...${DECOLOR}"
case $(os) in
    manjaro | ubuntu | debian)
        BASHRC="/etc/bash.bashrc"
        ;;
    fedora | centos | almalinux | rocky)
        BASHRC="/etc/bashrc"
        ;;
esac
sed -i '/^alias ll/d' "$targethome"/.bashrc
sed -i '/# POST INSTALLATION/Q' "$BASHRC" \
    && cat ./configurations/bashrc-{common,"$(os)"} >> "$BASHRC"

# Fonts ##########################################################################################################
ask "Do you want to install fonts?" "install_fonts"

##################################################################################################################
rm -rf resources
finish_msg