#!/bin/bash
# shellcheck disable=SC2068,SC1091,SC1090,SC2154

trap 'tput cnorm; echo; exit 3' SIGINT

print_help() {
    printf "%s" "
-----------------------------------+-----------------------------------------------------
             Switches              |                     Description
-----------------------------------+-----------------------------------------------------
    --update-hosts, --host         |   Update only /etc/hosts and ~/.ssh/config files
-----------------------------------+-----------------------------------------------------
            --bashrc               |   Update only bashrc files
-----------------------------------+-----------------------------------------------------
   --scripts, --install-scripts    |   Install scripts only
-----------------------------------+-----------------------------------------------------
 --templates, --install-templates  |   Install templates only
-----------------------------------+-----------------------------------------------------
     --fonts, --install-fonts      |   Install fonts only
-----------------------------------+-----------------------------------------------------
       --kube, --kubernetes        |   Install Kubernetes client and Krew
-----------------------------------+-----------------------------------------------------
           --noresources           |   Don't download and install resources
-----------------------------------+-----------------------------------------------------
           --help, -h              |   Show this help message
-----------------------------------+-----------------------------------------------------
"
}

case $1 in
    --help | -h)
        print_help
        exit 0
        ;;
esac

# IMPORT REQUIREMENTS #############################################################################
install_resources() {
    [[ $UID == "0" ]] || { echo "You are not root." >&2; exit 1; }
    local resources_latest_version
    resources_latest_version=$(
        curl -v https://github.com/fkia87/resources/releases/latest 2>&1 | \
        grep -i '< location:' | rev | cut -d / -f 1 | rev | sed 's/\r//g'
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
    rm -rf "$resources_latest_version".tar.gz
}

# Don't install resources if --noresource is given
noresource_given=false
new_args=()
for arg in "$@"; do
    if [[ "$arg" =~ --noresource ]]; then
        noresource_given=true
    else
        new_args+=("$arg")
    fi
done

# remove --noresource from arguments
# This command actually replaces current arguments with $new_args we 
# just created:
set -- "${new_args[@]}"

# Install resources if --noresource is not given
$noresource_given || install_resources

. /etc/profile
###################################################################################################
source ./common
checkuser
strt_msg
eval "$(cat /etc/os-release)"
REL=${VERSION_ID%%.*}
get_target_user
###################################################################################################
while [[ $# -gt 0 ]]; do
    quit_after=1
    case $1 in
        --update-host* | --host*)
            echo -e "${BLUE}Updating SSH configurations...${DECOLOR}"
            install_ssh_config
            config_hosts
            shift 1
            ;;
        --bashrc)
            config_bashrc
            shift 1
            ;;
        --install-script* | --script*)
            install_scripts
            shift 1
            ;;
        --install-template* | --template*)
            install_templates
            shift 1
            ;;
        --install-font* | --font*)
            install_fonts
            shift 1
            ;;
        --kube*)
            kubernetes_stuff
            shift 1
            ;;
        *)
            echo "Ignored invalid option: $1"
            shift 1
            ;;
    esac
done

if [[ $quit_after -eq 1 ]]; then
    rm -rf resources
    finish_msg
    exit 0
fi
###################################################################################################
ask "Remove password for sudoers?" "passwordless_sudo"
ask "Config journald?" "config_journald"
ask "Set default scale for QT applications to 2?" "set_qt_scale_2"
ask "Configure Kubernetes client?" "kubernetes_stuff"

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
    rocky*)
        config_dnf() {
            echo -e "${BLUE}Writing \"DNF\" configurations...${DECOLOR}"
            cp ./configurations/dnf.conf /etc/dnf/dnf.conf
            echo -e "${BLUE}Installing \"EPEL\" and \"rpm fusion repositories\"...${DECOLOR}"
            dnf -y install epel-release \
            https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-"${REL}".noarch.rpm \
            https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-"${REL}".noarch.rpm
        }
        ask "Config dnf and rpmfusion?" "config_dnf"
        ;;
esac

# Hosts, SSH and proxy configuration ##############################################################
ask "Configure SSH tunnels?" "config_proxy" || \
    ask "Setup SSH keys?" "config_ssh" || \
    ask "Copy SSH config file?" "install_ssh_config"
ask "Install \"/etc/hosts\"?" "config_hosts"

###################################################################################################
ask "Install scripts?" "install_scripts"
ask "Install Templates?" "install_templates"

# GoFlex ##########################################################################################
ask "Configure \"GoFlex\"?" "config_goflex"

# Terminator ######################################################################################
ask "Configure \"Terminator\"?" "config_terminator"

# Package installation ############################################################################
ask "Install useful packages? (duf, bat, curl, ...)" "useful_packages"

# Autostart xbanish (Hide mouse cursor when typing) ###############################################
ask "Autostart xbanish (Hide mouse cursor when typing)?" "config_xbanish"

# bachrc ##########################################################################################
ask "Config bashrc?" "config_bashrc"

# Fonts ###########################################################################################
ask "Install fonts?" "install_fonts"

# Nekoray #########################################################################################
# ask "Install routes for Nekoray?" "install_nekoray_routes"

###################################################################################################
rm -rf resources
finish_msg