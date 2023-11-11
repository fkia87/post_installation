#!/bin/bash
# shellcheck disable=SC2068,SC1091,SC1090,SC2154

# IMPORT REQUIREMENTS #############################################################################
install_resources() {
    [[ $UID == "0" ]] || { echo "You are not root." >&2; exit 1; }
    local resources_latest_version
    resources_latest_version=$(
        curl -v https://github.com/fkia87/resources/releases/latest 2>&1 | \
        grep -i location | rev | cut -d / -f 1 | rev | sed 's/\r//g'
    )
    echo -e "Downloading resources..."
    rm -rf "$resources_latest_version".tar.gz
    wget https://github.com/fkia87/resources/archive/refs/tags/"$resources_latest_version".tar.gz \
        || { echo -e "Error downloading required files from Github." >&2; exit 1; }
    tar xvf ./"$resources_latest_version".tar.gz || { echo -e "Extraction failed." >&2; exit 1; }
    cd ./resources-"${resources_latest_version/v/}" || exit 2
    ./INSTALL.sh
    cd .. || exit 2
    rm -rf ./resources*
    . /etc/profile
}

install_resources
###################################################################################################
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

## GRUB ###########################################################################################
ask "Grub configurations? (SELinux, pcie_aspm, ...)" "config_grub"

# Create directories ##############################################################################
create_dirs

## DNF ############################################################################################
case $(os) in
    fedora)
        config_dnf() {
            echo -e "${BLUE}Writing \"DNF\" configurations...${DECOLOR}"
            cp ./configurations/dnf.conf /etc/dnf/dnf.conf
            echo -e "${BLUE}Installing \"rpm fusion repositories\"...${DECOLOR}"
            dnf -y install \
            https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"${REL}".noarch.rpm \
            https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"${REL}"\
            .noarch.rpm
        }
        ask "Config dnf and rpmfusion?" "config_dnf"
        ;;
esac

# Hosts, SSH and proxy configuration ##############################################################
ask "Configure SSH tunnels?" "config_proxy" || ask "Setup SSH keys?" "config_ssh" || \
ask "Copy SSH config file?" "install -o $targetuser -g $targetuser ./configurations/ssh/* \
$targethome/.ssh"
ask "Install \"/etc/hosts\"?" "config_hosts"

###################################################################################################
ask "Install scripts?" "install_scripts"
ask "Install Templates?" "install_templates"

# GoFlex ##########################################################################################
ask "Configure \"GoFlex\"?" "config_goflex"

# Package installation ############################################################################
ask "Install useful packages? (duf, bat, curl, ...)" "useful_packages"
# Autostart xbanish (Hide mouse cursor when typing) ###############################################
autostart_dir="$targethome/.config/autostart"
mkdir -p "$autostart_dir"
cp ./configurations/xbanish.desktop "$autostart_dir"

# bachrc ##########################################################################################
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

# Fonts ###########################################################################################
ask "Install fonts?" "install_fonts"

###################################################################################################
rm -rf resources
finish_msg