#!/bin/bash
rpath="$(readlink ${BASH_SOURCE})"
if [ -z "$rpath" ];then
    rpath=${BASH_SOURCE}
fi
root="$(cd $(dirname $rpath) && pwd)"
cd "$root"
shellHeaderLink='https://pic711.oss-cn-shanghai.aliyuncs.com/sh/shell-header.sh'
if [ -e /etc/shell-header.sh ];then
    source /etc/shell-header.sh
else
    (cd /tmp && wget -q "$shellHeaderLink") && source /tmp/shell-header.sh
fi
# write your code below

option=$1

#git
(cd git && bash setGit)

#shell
if [ "$option" == "-o" ];then
    (cd shell && bash 10-zsh-installer.sh -o && bash 20-set-zsh-theme.sh -o && bash 30-config-shell.sh all)
else
    (cd shell && bash 10-zsh-installer.sh && bash 20-set-zsh-theme.sh && bash 30-config-shell.sh all)
fi

##vim
#if [ "$option" == "-o" ];then
#    (cd supervim && bash install.sh -o vim)
#else
#    (cd supervim && bash install.sh vim)
#fi

##nvim
#if [ "$option" == "-o" ];then
#    (cd supervim && bash install.sh -o nvim)
#else
#    (cd supervim && bash install.sh nvim)
#fi

(cd tmux && bash install.sh)
