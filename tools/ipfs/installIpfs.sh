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
ipfsLink=https://github.com/ipfs/go-ipfs/releases/download/v0.10.0/go-ipfs_v0.10.0_linux-amd64.tar.gz
ipfsTar=${ipfsLink##*/}
ipfsDir=${ipfsTar%%_*}
dest=/usr/local
ipfsRoot=${dest}/${ipfsDir}
ipfsConfigRoot=/root/.ipfs
ipfsConfigFile=${ipfsConfigRoot}/config
gatewayPort=3080

install(){
    _linux
    _root
    # download and extract
    (
        cd /tmp && curl -L -O ${ipfsLink} || { echo "download ipfs release failed!"; return 1; }
        echo "extract ${ipfsTar}..."
        if [ ! -d ${dest} ];then
            mkdir -p ${dest}
        fi
        tar -C ${dest} xvf ${ipfsTar} || { echo "extract ${ipfsTar} failed!"; return 1; }
    )

    # init
    ipfs init

    # check ipfsConfigFile
    if [ ! -e ${ipfsConfigFile} ];then
        echo "No such file: ${ipfsConfigFile}, init ipfs failed!"
        return 1
    fi

    # config 
    ## backup
    cp ${ipfsConfigFile} ${ipfsConfigFile}.old
    sed -i -e "s|127.0.0.1/tcp/8080|0.0.0.0/tcp/${gatewayPort}|" ${ipfsConfigFile}

    # make service file
    cat<<-EOF>/tmp/ipfs.service
[Unit]
Description= ipfs daemon
After=network.target

[Service]

Type=simple
#ExecStartPre=
ExecStart=ipfs daemon
#ExecStartPost=

#ExecStop=
#ExecStopPost=

#User=USER
#WorkingDirectory=/path/to/wd
#Restart=always
#Environment=
[Install]
WantedBy=multi-user.target

EOF
    mv /tmp/ipfs.service /etc/systemd/system
    systemctl daemon-reload


    # start service
    systemctl enable --now ipfs.service

}

uninstall(){
    _root
    systemctl stop ipfs.service
    /bin/rm -rf /etc/systemd/system/ipfs.service
    systemctl daemon-reload
    /bin/rm -rf ${ipfsRoot}
    /bin/rm -rf ${ipfsConfigRoot}
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
