#!/bin/bash
rpath="$(readlink ${BASH_SOURCE})"
if [ -z "$rpath" ];then
    rpath=${BASH_SOURCE}
fi
this="$(cd $(dirname $rpath) && pwd)"
cd "$this"
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

_runAsRoot(){
    cmd="${*}"
    local rootID=0
    if [ "${EUID}" -ne "${rootID}" ];then
        echo -n "Not root, try to run as root.."
        # or sudo sh -c ${cmd} ?
        if eval "sudo ${cmd}";then
            echo "ok"
            return 0
        else
            echo "failed"
            return 1
        fi
    else
        # or sh -c ${cmd} ?
        eval "${cmd}"
    fi
}

rootID=0
function _root(){
    if [ ${EUID} -ne ${rootID} ];then
        echo "Need run as root!"
        exit 1
    fi
}

editor=vi
if command -v vim >/dev/null 2>&1;then
    editor=vim
fi
if command -v nvim >/dev/null 2>&1;then
    editor=nvim
fi
###############################################################################
# write your code below (just define function[s])
# function is hidden when begin with '_'
###############################################################################
# TODO
_createDirWhenNeed(){
    local dir=${1}
    if [ ! -d "${dir}" ];then
        echo -n "mkdir ${dir} .. "
        mkdir -p "${dir}"
        if [ $? -eq 0 ];then
            echo "ok"
            return 0
        else
            echo "failed"
            return 1
        fi
    fi
}

_fullpath(){
    local path="${1}"
    if [ -z "${path}" ];then
        _err "missing path"
        return 1
    fi

    if [ ! -d "${path}" ];then
        _err "cannot find direcotry: ${path}"
        return 1
    fi

    cd "${path}" && pwd
}

UID=0
GID=0

install(){
    local usage="install <username> <password> <install destination>"
    local username=${1}
    local password=${2}
    local dest=${3}
    if [ -z "${username}" ] || [ -z "${password}" ] || [ -z "${dest}" ];then
        echo "${usage}"
        exit 1
    fi

    if [ ! -d "${dest}" ];then
        echo -n "mkdir ${dest} .. "
        mkdir -p ${dest}
        if [ "$?" -eq 0 ];then
            echo "ok"
        else
            echo "failed"
            exit 1
        fi
    fi
    if ! _createDirWhenNeed "${dest}";then
        exit 1
    fi

    local configName=./config
    local downloadName=./download
    local watchName=./watch
    local configDir="${dest}/${configName}"
    local downloadDir="${dest}/${downloadName}"
    local watchDir="${dest}/${watchName}"

    _createDirWhenNeed ${configDir}
    _createDirWhenNeed ${downloadDir}
    _createDirWhenNeed ${watchDir}

    local composeFile="${dest}/docker-compose.yml"
    echo -n "write docker compose file to ${composeFile} .. "
    cat<<-EOF>${composeFile}
version: "2.1"
services:
  transmission:
    image: ghcr.io/linuxserver/transmission
    container_name: transmission
    environment:
      - PUID=${UID}
      - PGID=${GID}
      - TZ=Asia/Shanghai
      - TRANSMISSION_WEB_HOME=/combustion-release/ #optional
      - USER=${username} #optional
      - PASS=${password} #optional
    volumes:
      - ${configName}:/config
      - ${downloadName}:/downloads
      - ${watchName}:/watch
    ports:
      - 9091:9091
      - 51413:51413
      - 51413:51413/udp
    restart: unless-stopped
EOF
    if [ $? -eq 0 ];then
        echo "ok"
        echo "transmission uid: ${UID} gid: ${GID}"
        echo "run 'docker-compose up -d' in ${dest} to start transmission."
    else
        echo "failed"
    fi

    if ! command -v docker >/dev/null 2>&1;then
        echo "Warning: need docker command"
    fi
    if ! command -v docker-compose >/dev/null 2>&1;then
        echo "Warning: need docker-compose command"
    fi

}

em(){
    $editor $0
}

###############################################################################
# write your code above
###############################################################################
function _help(){
    cat<<EOF2
Usage: $(basename $0) ${bold}CMD${reset}

${bold}CMD${reset}:
EOF2
    # perl -lne 'print "\t$1" if /^\s*(\w+)\(\)\{$/' $(basename ${BASH_SOURCE})
    # perl -lne 'print "\t$2" if /^\s*(function)?\s*(\w+)\(\)\{$/' $(basename ${BASH_SOURCE}) | grep -v '^\t_'
    perl -lne 'print "\t$2" if /^\s*(function)?\s*(\w+)\(\)\{$/' $(basename ${BASH_SOURCE}) | perl -lne "print if /^\t[^_]/"
}

function _loadENV(){
    if [ -z "$INIT_HTTP_PROXY" ];then
        echo "INIT_HTTP_PROXY is empty"
        echo -n "Enter http proxy: (if you need) "
        read INIT_HTTP_PROXY
    fi
    if [ -n "$INIT_HTTP_PROXY" ];then
        echo "set http proxy to $INIT_HTTP_PROXY"
        export http_proxy=$INIT_HTTP_PROXY
        export https_proxy=$INIT_HTTP_PROXY
        export HTTP_PROXY=$INIT_HTTP_PROXY
        export HTTPS_PROXY=$INIT_HTTP_PROXY
        git config --global http.proxy $INIT_HTTP_PROXY
        git config --global https.proxy $INIT_HTTP_PROXY
    else
        echo "No use http proxy"
    fi
}

function _unloadENV(){
    if [ -n "$https_proxy" ];then
        unset http_proxy
        unset https_proxy
        unset HTTP_PROXY
        unset HTTPS_PROXY
        git config --global --unset-all http.proxy
        git config --global --unset-all https.proxy
    fi
}


case "$1" in
     ""|-h|--help|help)
        _help
        ;;
    *)
        "$@"
esac
