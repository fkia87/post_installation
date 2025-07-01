#!/bin/bash
# shellcheck disable=SC2068,SC1091,SC1090,SC2154,SC2034

trap 'tput cnorm; echo; exit 3' SIGINT

print_help() {
    printf "%s" "
-----------------------------------+------------------------------------------------------------
             Switches              |                        Description
-----------------------------------+------------------------------------------------------------
    --update-hosts, --host         |   Update only /etc/hosts and ~/.ssh/config files
-----------------------------------+------------------------------------------------------------
            --bashrc               |   Update only bashrc files
-----------------------------------+------------------------------------------------------------
   --scripts, --install-scripts    |   Install scripts
-----------------------------------+------------------------------------------------------------
 --templates, --install-templates  |   Install templates
-----------------------------------+------------------------------------------------------------
     --fonts, --install-fonts      |   Install fonts
-----------------------------------+------------------------------------------------------------
       --kube, --kubernetes        |   Install Kubernetes client and Krew
-----------------------------------+------------------------------------------------------------
            --gitconfig            |   Install .gitconfig file
-----------------------------------+------------------------------------------------------------
  --git-prompt, --bash-git-prompt  |   Install Bash Git Prompt
-----------------------------------+------------------------------------------------------------
           --noresources           |   Don't download and install resources (Already installed)
-----------------------------------+------------------------------------------------------------
            --help, -h             |   Show this help message
-----------------------------------+------------------------------------------------------------
"
}

case $1 in
    --help | -h)
        print_help
        exit 0
        ;;
esac

# IMPORT REQUIREMENTS #############################################################################
for cmd in curl mktemp; do
    command -v $cmd > /dev/null || { echo -e "$cmd not fount. Exiting..." >&2; exit 1; }
done

github_get_latest_version() {
    # Usage: Give it a GitHub URL as the first argument
    curl -v "${1}/releases/latest" 2>&1 | grep -i '< location:' | rev | cut -d / -f 1 | rev | sed 's/\r//g'
}

install_resources() {
    [[ $UID == "0" ]] || { echo "You are not root." >&2; exit 1; }
    local gh_url; gh_url="https://github.com/fkia87/resources"
    local _latest_version; _latest_version=$(github_get_latest_version "$gh_url")
    echo -e "Downloading resources..."
    local TMPDIR; TMPDIR=$(mktemp -d)
    curl -sL --output "$TMPDIR/resources-$_latest_version.tar.gz" \
        "$gh_url/archive/refs/tags/$_latest_version.tar.gz" \
        || { echo -e "Error downloading files from Github." >&2; exit 1; }
    tar xf "$TMPDIR/resources-$_latest_version.tar.gz" -C "$TMPDIR" \
        || { echo -e "Extraction failed." >&2; exit 1; }
    # 'v' is removed from the name of the extracted file:
    "$TMPDIR/resources-${_latest_version#v}/INSTALL.sh"
    RELOAD=1
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

. /etc/profile 2> /dev/null
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
        --git-prompt | --bash-git-prompt)
            install_bash_git_prompt
            shift 1
            ;;
        --gitconfig)
            install_gitconfig
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
ask "Install .gitconfig?" install_gitconfig
ask "Install 'bash-git-prompt'?" "install_bash_git_prompt"
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
            https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm \
            https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
            dnf config-manager setopt fedora-cisco-openh264.enabled=1
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