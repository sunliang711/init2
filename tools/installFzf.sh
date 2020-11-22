#!/bin/bash
rpath="$(readlink ${BASH_SOURCE})"
if [ -z "$rpath" ];then
    rpath=${BASH_SOURCE}
fi
thisDir="$(cd $(dirname $rpath) && pwd)"
cd "$thisDir"

user="${SUDO_USER:-$(whoami)}"
home="$(eval echo ~$user)"

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
cyan=$(tput setaf 5)
bold=$(tput bold)
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
###############################################################################
        # write your code below (just define function[s])
###############################################################################
# TODO
install(){
    #install binary
    # if [ ! -e $GOPATH/bin/fzf ];then
    #     cmd="go get -u github.com/junegunn/fzf"
    #     echo "$cmd ..."
    #     bash -c "$cmd > /dev/null" && { echo "Done"; } || { echo "Install fzf error!"; exit 1; }
    # fi

    # git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    git clone --depth 1 https://gitee.com/quick-source/fzf.git ~/.fzf
    ~/.fzf/install

    if ! grep -q '#BEGIN FZF function' ~/.zshrc;then
        echo "add source $(pwd)/fzffunction.sh in .zshrc"
        cat<<-EOF>>~/.zshrc
		#BEGIN FZF function
		source $(pwd)/fzffunctions.sh
		#END FZF function
		EOF
    fi

    if ! grep -q '#BEGIN FZF function' ~/.bashrc;then
        echo "add source $(pwd)/fzffunction.sh in .bashrc"
        cat<<-EOF>>~/.bashrc
		#BEGIN FZF function
		source $(pwd)/fzffunctions.sh
		#END FZF function
		EOF
    fi

    if ! command -v fd >/dev/null 2>&1;then
        echo "${red}Warning: install fd or fd-find for fzf${reset}"
    fi

    if ! command -v bat >/dev/null 2>&1;then
        echo "${cyan}Recommend: install bat for fzf preview${reset}"
    fi
}



###############################################################################
# write your code above
###############################################################################
help(){
    cat<<EOF2
Usage: $(basename $0) ${bold}CMD${reset}

${bold}CMD${reset}:
EOF2
    perl -lne 'print "\t$1" if /^\s*(\w+)\(\)\{$/' $(basename ${BASH_SOURCE}) | grep -v runAsRoot
}

case "$1" in
     ""|-h|--help|help)
        help
        ;;
    *)
        "$@"
esac
