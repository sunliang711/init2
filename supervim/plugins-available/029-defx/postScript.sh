#!/bin/bash

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
cyan=$(tput setaf 5)
bold=$(tput bold)
reset=$(tput sgr0)

rpath="$(readlink ${BASH_SOURCE})"
if [ -z "$rpath" ];then
    rpath=${BASH_SOURCE}
fi
thisScriptDir="$(cd $(dirname $rpath) && pwd)"

# available ENV variables:
    # VIM               which vim? [vim/nvim]
    # vimroot           vim config dir: ~/.config/nvim or ~/.vim
    # installRootDir    eg: ../../  (the dir contains install.sh)

if [[ "$VIM" = "nvim" ]];then
    if ! pip3 list | grep -i pynvim >/dev/null 2>&1;then
        echo "defx needs python support, install pynvim..."
        pip3 install --user pynvim || { echo "${red}Warning${reset}: faild. Please use pip3 to install pynvim manaually!"; }
    fi
fi

if ! pip3 list | grep -i send2trash >/dev/null 2>&1;then
    echo "defx needs send2trash python module,install it..."
    pip3 install --user send2trash || { echo "${red}Warning${reset}: faild. Please install use pip3 to install send2trans manaually!"; }
fi
