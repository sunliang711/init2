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

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

user="${SUDO_USER:-$(whoami)}"
home="$(eval echo ~$user)"

# export TERM=xterm-256color

# Use colors, but only if connected to a terminal, and that terminal
# supports them.
if which tput >/dev/null 2>&1; then
  ncolors=$(tput colors 2>/dev/null)
fi
if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    CYAN="$(tput setaf 5)"
    BOLD="$(tput bold)"
    NORMAL="$(tput sgr0)"
else
    RED=""
    GREEN=""
    YELLOW=""
    CYAN=""
    BLUE=""
    BOLD=""
    NORMAL=""
fi

_err(){
    echo "$*" >&2
}

_command_exists(){
    command -v "$@" > /dev/null 2>&1
}

rootID=0

_runAsRoot(){
    local trace=0
    local subshell=0
    local nostdout=0
    local nostderr=0

    local optNum=0
    for opt in ${@};do
        case "${opt}" in
            --trace|-x)
                trace=1
                ((optNum++))
                ;;
            --subshell|-s)
                subshell=1
                ((optNum++))
                ;;
            --no-stdout)
                nostdout=1
                ((optNum++))
                ;;
            --no-stderr)
                nostderr=1
                ((optNum++))
                ;;
            *)
                break
                ;;
        esac
    done

    shift $(($optNum))
    local cmd="${*}"
    bash_c='bash -c'
    if [ "${EUID}" -ne "${rootID}" ];then
        if _command_exists sudo; then
            bash_c='sudo -E bash -c'
        elif _command_exists su; then
            bash_c='su -c'
        else
            cat >&2 <<-'EOF'
			Error: this installer needs the ability to run commands as root.
			We are unable to find either "sudo" or "su" available to make this happen.
			EOF
            exit 1
        fi
    fi

    local fullcommand="${bash_c} ${cmd}"
    if [ $nostdout -eq 1 ];then
        cmd="${cmd} >/dev/null"
    fi
    if [ $nostderr -eq 1 ];then
        cmd="${cmd} 2>/dev/null"
    fi

    if [ $subshell -eq 1 ];then
        if [ $trace -eq 1 ];then
            (set -x; ${bash_c} "${cmd}")
        else
            (${bash_c} "${cmd}")
        fi
    else
        if [ $trace -eq 1 ];then
            set -x; ${bash_c} "${cmd}";set +x;
        else
            ${bash_c} "${cmd}"
        fi
    fi
}

function _insert_path(){
    if [ -z "$1" ];then
        return
    fi
    echo -e ${PATH//:/"\n"} | grep -c "^$1$" >/dev/null 2>&1 || export PATH=$1:$PATH
}

_run(){
    local trace=0
    local subshell=0
    local nostdout=0
    local nostderr=0

    local optNum=0
    for opt in ${@};do
        case "${opt}" in
            --trace|-x)
                trace=1
                ((optNum++))
                ;;
            --subshell|-s)
                subshell=1
                ((optNum++))
                ;;
            --no-stdout)
                nostdout=1
                ((optNum++))
                ;;
            --no-stderr)
                nostderr=1
                ((optNum++))
                ;;
            *)
                break
                ;;
        esac
    done

    shift $(($optNum))
    local cmd="${*}"
    bash_c='bash -c'

    local fullcommand="${bash_c} ${cmd}"
    if [ $nostdout -eq 1 ];then
        cmd="${cmd} >/dev/null"
    fi
    if [ $nostderr -eq 1 ];then
        cmd="${cmd} 2>/dev/null"
    fi

    if [ $subshell -eq 1 ];then
        if [ $trace -eq 1 ];then
            (set -x; ${bash_c} "${cmd}")
        else
            (${bash_c} "${cmd}")
        fi
    else
        if [ $trace -eq 1 ];then
            set -x; ${bash_c} "${cmd}";set +x;
        else
            ${bash_c} "${cmd}"
        fi
    fi
}

function _root(){
    if [ ${EUID} -ne ${rootID} ];then
        echo "Requires root privilege." 1>&2
        exit 1
    fi
}

function _linux(){
    if [ "$(uname)" != "Linux" ];then
        echo "Requires Linux" 1>&2
        exit 1
    fi
}

function _wait(){
    # secs=$((5 * 60))
    secs=${1:?'missing seconds'}

    while [ $secs -gt 0 ]; do
       echo -ne "$secs\033[0K\r"
       sleep 1
       : $((secs--))
    done
    echo -ne "\033[0K\r"
}

ed=vi
if _command_exists vim; then
    ed=vim
fi
if _command_exists nvim; then
    ed=nvim
fi
# use ENV: editor to override
if [ -n "${editor}" ];then
    ed=${editor}
fi
###############################################################################
# write your code below (just define function[s])
# function is hidden when begin with '_'
cmd='qbittorrent-nox'
user='qbittorrent'
group='qbittorrent'

install(){
    _root
    if ! command -v "${cmd}" >/dev/null 2>&1;then
        echo "install ${cmd}"
        # apt update
        # apt install -y "${cmd}" || { echo "install ${cmd} failed"; exit 1; }
        link="https://source711.oss-cn-shanghai.aliyuncs.com/qbittorrent-nox/linux/x64/4.3.8/qbittorrent-nox"
        (
        cd /tmp
        curl -LO "${link}" && mv qbittorrent-nox /usr/local/bin || { echo "download qbittorrent-nox failed"; exit 1; }
        chmod +x /usr/local/bin/qbittorrent-nox
        )
    fi

    if ! id -u ${user} >/dev/null 2>&1;then
        echo "create user: ${user} "
        useradd -m ${user} || { echo "create user failed"; exit 1; }
        # add ${user} to sudoer
        _addsudo ${user}
    fi

    cp ${this}/smb.sh /usr/local/bin/smb.sh

    port=8083
    echo "webui port: ${port} "
    fullPath="$(which ${cmd}) --webui-port=${port}"

    start_pre=
    stop=

    echo "config smb mount? [y/n]"
    read configSmb
    if [ "${configSmb}" == y ];then
        read -p "enter smb ip: " smbIp
        read -p "enter smb name: " smbName
        mountDir=/home/${user}/Downloads
        read -p "enter smb user: " smbUser
        read -p "enter smb password: " smbPass
        #read -p "enter smb mount as user: " asUser
        asUser=${user}
        start_pre="/usr/local/bin/smb.sh mount ${smbIp} ${smbName} ${mountDir} ${smbUser} ${smbPass} ${asUser}"
        stop="/usr/local/bin/smb.sh umount ${mountDir}"

    fi
    # local usage="usage: mount <smb_ip> <smb_name> <mount_dir> <smb_user> <smb_password> <as_user>"

    sed -e "s|<EXE>|${fullPath}|g" \
        -e "s|<START_PRE>|${start_pre}|g" \
        -e "s|<STOP>|${stop}|g" \
        -e "s|<USER>|${user}|g" ${this}/qbittorrent.service >/etc/systemd/system/qbittorrent.service

    systemctl daemon-reload
    systemctl start qbittorrent.service

    echo "config file at: $HOME/.config/qBittorrent/qBittorrent.conf"

}

_addsudo(){
    user=${1:?'missing user'}
    echo "add ${user} to sudoers"
    if ! command -v sudo >/dev/null 2>&1;then
        apt install sudo || { echo "install sudo failed."; exit 1; }
    fi
    cat>>/etc/sudoers.d/nopass<<-EOF
${user} ALL=(ALL:ALL) NOPASSWD:ALL
EOF

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
