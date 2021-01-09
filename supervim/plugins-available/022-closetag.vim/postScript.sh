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
