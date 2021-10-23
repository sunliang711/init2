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
serverPubkey=server-publickey
serverPrikey=server-privatekey
serverConfigName=wg0
serverConfigFile=${serverConfigName}.conf
MTU=1420
subnet=10.10.10
serverIp=${subnet}.1/24
serverPort=51820
# clientDNS=223.5.5.5
tableNo=10



configServer(){
    set -e
    _root
    if [ ! -d ${wireguardRoot} ];then
        mkdir -p ${wireguardRoot}
    fi
    # create server key pair when not exist
    if [ ! -f ${wireguardRoot}/${serverPrikey} ];then
        echo "create server key pair"
        wg genkey | tee ${wireguardRoot}/${serverPrikey} | wg pubkey | tee ${wireguardRoot}/${serverPubkey}
    fi
    echo -n "Enter client gateway: "
    read clientGateway

    if [ ! -f ${wireguardRoot}/${serverConfigFile} ];then
        interface=$(ip -o -4 route show to default | awk '{print $5}')
        cat<<-EOF>${wireguardRoot}/${serverConfigFile}
[Interface]
Address = ${serverIp}
MTU = ${MTU}
SaveConfig = true
PreUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -t nat -A POSTROUTING -o ${interface} -j MASQUERADE;ip rule add from ${subnet}.0/24 table ${tableNo};ip route add default via ${clientGateway} table ${tableNo};
PostDown = iptables -t nat -D POSTROUTING -o ${interface} -j MASQUERADE; ip rule del from ${subnet}.0/24 table ${tableNo};ip route del default table ${tableNo};
ListenPort = ${serverPort}
PrivateKey = $(cat ${wireguardRoot}/${serverPrikey})

EOF
    else
        $ed ${wireguardRoot}/${serverConfigFile}
    fi

}

addClient(){
    set -e
    _root
    stop

    clientName=${1:?'missing client name'}
    hostNumber=${2:?'missing host number(x of ${subnet}.x)'}
    endpoint=${3:?'missing server endpoint(ip or domain)'}
    clientDNS=${4:?'missing client DNS'}

    echo "generate client key pair"
    wg genkey | tee ${wireguardRoot}/client-${clientName}.privatekey | wg pubkey | tee ${wireguardRoot}/client-${clientName}.publickey

    echo "generate client config file"
    cat<<-EOF>${wireguardRoot}/client-${clientName}.conf
[Interface]
  PrivateKey = $(cat ${wireguardRoot}/client-${clientName}.privatekey)
  Address = ${subnet}.${hostNumber}/24
  DNS = ${clientDNS}
  MTU = ${MTU}

[Peer]
  PublicKey = $(cat ${wireguardRoot}/${serverPubkey})
  Endpoint = ${endpoint}:${serverPort}
  AllowedIPs = 0.0.0.0/0, ::0/0
  PersistentKeepalive = 25
EOF


    echo "add client peer to server"
    cat<<-EOF>>${wireguardRoot}/${serverConfigFile}
# begin client-${clientName}
[Peer]
PublicKey = $(cat ${wireguardRoot}/client-${clientName}.publickey)
AllowedIPs = ${subnet}.${hostNumber}/32
# end client-${clientName}
EOF
cat<<-EOF
    run 'wireguard.sh restart to restart server after add client'
    run 'wireguard.sh exportClientConfig ${clientName} to export client qrcode'
EOF
}

removeClient(){
    clientName=${1:?'missing client name'}
    set -e
    _root
    rm -rf ${wireguardRoot}/client-${clientName}.privatekey
    rm -rf ${wireguardRoot}/client-${clientName}.publickey
    rm -rf ${wireguardRoot}/client-${clientName}.conf
    sed -i -e "/# begin client-${clientName}/,/# end client-${clientName}/d" ${wireguardRoot}/${serverConfigFile}
}

listClient(){
    cd ${wireguardRoot}
    ls client-*.conf
}

configClient(){
    echo "TODO"
}

start(){
    set -e
    _root
    systemctl start wg-quick@wg0
}

stop(){
    set -e
    _root
    systemctl stop wg-quick@wg0
}

exportClientConfig(){
    set -e
    _root
    clientName=${1:?'missing client name'}
    if [ ! -f ${wireguardRoot}/client-${clientName}.conf ];then
        echo "no such client, add client first!"
        exit 1
    fi
    cat ${wireguardRoot}/client-${clientName}.conf | qrencode -t ansiutf8
    cat ${wireguardRoot}/client-${clientName}.conf
}

restart(){
    stop
    start
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
