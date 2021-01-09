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


git clone --depth 1 https://gitee.com/quick-source/fzf.git ~/.fzf
~/.fzf/install --all

# available ENV variables:
    # VIM               which vim? [vim/nvim]
    # vimroot           vim config dir: ~/.config/nvim or ~/.vim
    # installRootDir    eg: ../../  (the dir contains install.sh)
if ! command -v bat >/dev/null 2>&1;then
    echo "Need 'bat' command."
fi

if ! command -v fd >/dev/null 2>&1;then
    echo "Need 'fd' command."
fi

if ! command -v rg >/dev/null 2>&1;then
    echo "Need 'rg' command."
fi
