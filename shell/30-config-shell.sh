#!/bin/bash
if [ -e /tmp/proxy ];then
    source /tmp/proxy
fi
rpath="$(readlink $BASH_SOURCE)"
if [ -z "$rpath" ];then
    rpath="$BASH_SOURCE"
fi
root="$(cd $(dirname $rpath) && pwd)"
cd "$root"
user=${SUDO_USER:-$(whoami)}
home=$(eval echo ~$user)

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
cyan=$(tput setaf 5)
reset=$(tput sgr0)
runAsRoot(){
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
        echo "Run cmd:\"${red}$cmd${reset}\" as root..."
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
startLine="##CUSTOM BEGIN v3"
endLine="##CUSTOM END v3"

usage(){
    cat<<-EOF
Usage: $(basename $0) CMD

CMD:
    install     bash|zsh
    uninstall   bash|zsh

    all         #to install all
    uall        #to uninstall all
EOF
    exit 1
}

bashrc="${home}/.bashrc"
zshrc="${home}/.zshrc"

install(){
    local type=${1}
    if [ -z "$type" ];then
        usage
    fi
    case $type in
        bash)
            configFile="$bashrc"
            ;;
        zsh)
            configFile="$zshrc"
            ;;
        *)
            usage
            ;;
    esac
    if [ ! -e "$home/.editrc" ] || ! grep -q 'bind -v' "$home/.editrc";then
        echo 'bind -v' >> "$home/.editrc"
    fi
    if [ ! -e "$home"/.inputrc ] || ! grep -q 'set editing-mode vi' "$home/.inputrc";then
        echo 'set editing-mode vi' >> "$home/.inputrc"
    fi
    case $(uname) in
        Darwin)
            # macOS uses libedit, 'bind -v' set vi mode,such as python interactive shell,mysql
            ;;
        Linux)
            # Linux uses readline library,'set editing-mode vi' set vi mode
            ;;
    esac

    if ! grep -q "$startLine" "$configFile";then
        cat <<-EOF >> "$configFile"
	$startLine
	export SHELLRC_ROOT=${root}
	source \${SHELLRC_ROOT}/shellrc
	$endLine
	EOF
    fi

    # if ! grep -q "$root/tools" $root/shellrc.d/local ;then
    #     echo "append_path $root/tools" >> $root/shellrc.d/local
    # fi
    echo "Please source $configFile manually just for the first time"

}

uninstall(){
    local type=${1}
    if [ -z "$type" ];then
        usage
    fi
    case $type in
        bash)
            configFile="$bashrc"
            ;;
        zsh)
            configFile="$zshrc"
            ;;
        *)
            usage
            ;;
    esac
    case $(uname) in
        Darwin)
            if [ -e "$home/.editrc" ];then
                sed -i.bak '/bind -v/d' $home/.editrc
                rm $home/.editrc.bak
            fi
            ;;
        Linux)
            if [ -e "$home/.inputrc" ];then
                sed -i '/set editing-mode vi/d' $home/.inputrc
            fi
            ;;
    esac

    sed -ibak -e "/$startLine/,/$endLine/ d" "$configFile"
    rm -rf ${configFile}bak
}


cmd=$1
shift

case $cmd in
    install)
        install "$@"
        ;;
    uninstall)
        uninstall "$@"
        ;;
    all)
        install bash
        install zsh
        ;;
    uall)
        uninstall bash
        uninstall zsh
        ;;
    *)
        usage
        ;;
esac
