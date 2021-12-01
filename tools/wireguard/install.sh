#!/bin/bash
if [ -z "${BASH_SOURCE}" ]; then
    this=${PWD}
else
    rpath="$(readlink ${BASH_SOURCE})"
    if [ -z "$rpath" ]; then
        rpath=${BASH_SOURCE}
    elif echo "$rpath" | grep -q '^/'; then
        # absolute path
        echo
    else
        # relative path
        rpath="$(dirname ${BASH_SOURCE})/$rpath"
    fi
    this="$(cd $(dirname $rpath) && pwd)"
fi

if [ -r ${SHELLRC_ROOT}/shellrc.d/shelllib ];then
    source ${SHELLRC_ROOT}/shellrc.d/shelllib
elif [ -r /tmp/shelllib ];then
    source /tmp/shelllib
else
    # download shelllib then source
    shelllibURL=https://gitee.com/sunliang711/init2/raw/master/shell/shellrc.d/shelllib
    (cd /tmp && curl -s -LO ${shelllibURL})
    if [ -r /tmp/shelllib ];then
        source /tmp/shelllib
    fi
fi


###############################################################################
# write your code below (just define function[s])
# function is hidden when begin with '_'
wireguardRoot=/etc/wireguard
install(){
    set -e
    _root
    cd ${this}
    # install soft
    echo 'deb http://ftp.debian.org/debian buster-backports main' | tee /etc/apt/sources.list.d/buster-backports.list
    apt update
    apt install wireguard qrencode -y
    case $(uname -m) in
        x86_64)
            apt install linux-image-amd64 linux-headers-amd64 -y
            ;;
        aarch64)
            apt install linux-image-arm64 linux-headers-arm64 -y
            ;;
    esac

    echo -n "Enter server port: "
    read serverPort
    # install wireguard.sh
    sed -e "s|<SERVER_PORT>|${serverPort}|g" wireguard.sh >/tmp/wireguard.sh && chmod +x /tmp/wireguard.sh
    mv /tmp/wireguard.sh /usr/local/bin

    # config server
    /usr/local/bin/wireguard.sh configServer

    # enable service
    systemctl enable wg-quick@wg0

    echo "${RED}Note: need reboot after install!${NORMAL}"

}

uninstall(){
    if ! _root;then
        exit 1
    fi
    /usr/local/bin/wireguard.sh stop
    if [ -e /usr/local/bin/wireguard.sh ];then
        rm -rf /usr/local/bin/wireguard.sh
    fi
    if [ -d ${wireguardRoot} ];then
        rm -rf ${wireguardRoot}
    fi
}

# write your code above
###############################################################################

em(){
    $ed $0
}

function _help(){
    cd "${this}"
    cat<<EOF2
Usage: $(basename $0) ${bold}CMD${reset}

${bold}CMD${reset}:
EOF2
    perl -lne 'print "\t$2" if /^\s*(function)?\s*(\S+)\s*\(\)\s*\{$/' $(basename ${BASH_SOURCE}) | perl -lne "print if /^\t[^_]/"
}

case "$1" in
     ""|-h|--help|help)
        _help
        ;;
    *)
        "$@"
esac
