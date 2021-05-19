#!/bin/bash
rpath="$(readlink ${BASH_SOURCE})"
if [ -z "$rpath" ];then
    rpath=${BASH_SOURCE}
fi
this="$(cd $(dirname $rpath) && pwd)"
cd "$this"

user="${SUDO_USER:-$(whoami)}"
home="$(eval echo ~$user)"

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
cyan=$(tput setaf 5)
bold=$(tput bold)
reset=$(tput sgr0)
function _runAsRoot(){
    verbose=0
    while getopts ":v" opt;do
        case "$opt" in
            v)
                verbose=1
                ;;
            \?)
                echo "Unknown option: \"$OPTARG\""
                exit 1
                ;;
        esac
    done
    shift $((OPTIND-1))
    cmd="$@"
    if [ -z "$cmd" ];then
        echo "${red}Need cmd${reset}"
        exit 1
    fi

    if [ "$verbose" -eq 1 ];then
        echo "run cmd:\"${red}$cmd${reset}\" as root."
    fi

    if (($EUID==0));then
        sh -c "$cmd"
    else
        if ! command -v sudo >/dev/null 2>&1;then
            echo "Need sudo cmd"
            exit 1
        fi
        sudo sh -c "$cmd"
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
install(){
    if [ $EUID -ne 0 ];then
        echo "Need root privilege"
        exit 1
    fi

    cat<<EOF
Press <C-c> to set apt proxy (apt source)first
Press <Enter> to continue
EOF
    read cnt

    apt-get remove docker docker-engine docker.io containerd runc
    apt-get update

    apt-get install \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg-agent \
        software-properties-common -y

    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

    apt-key fingerprint 0EBFCD88

    add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/debian \
        $(lsb_release -cs) \
        stable"

    apt-get update
    apt-get install docker-ce docker-ce-cli containerd.io -y

    echo "add $user to group docker"
    usermod -aG docker $user
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
