#!/bin/bash

source ~/.bashrc 2> /dev/null

_install_krew() {
    (
    cd "$(mktemp -d)" &&
    OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
    ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
    KREW="krew-${OS}_${ARCH}" &&
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
    tar zxvf "${KREW}.tar.gz" &&
    ./"${KREW}" install krew
    export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
    kubectl krew install ns ctx
    )
}

kubectl krew update >/dev/null 2>&1
case $? in
    130)
    echo -e "Upgrading..."
        kubectl krew upgrade
        ;;
    1)
        echo -e "\"Krew\" not found. Installing..."
        _install_krew
        ;;
    0)
        echo -e "\"Krew\" is already installed and the newest version."
        :
        ;;
    *)
        err "Unexpected exit code while configuring \"Krew\": $?"
        ;;
esac
