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

#git
(cd git && bash setGit)

#shell
(cd shell && bash installZsh.sh uninstall )
(cd shell && bash installZsh.sh install )

(./tools/installFzf.sh install)

(cd tmux && bash install.sh)
