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

if [ -r ${SHELLRC_ROOT}/shellrc.d/shelllib ];then
    source ${SHELLRC_ROOT}/shellrc.d/shelllib
elif [ -r /tmp/shelllib ];then
    source /tmp/shelllib
else
    # download shelllib then source
    shelllibURL=https://gitee.com/sunliang711/init2/raw/master/shell/shellrc.d/shelllib
    (cd /tmp && curl -s -LO ${shelllibURL})
    if [ -r /tmp/shelllib ];then
        source /tmp/shelllib
    fi
fi

###############################################################################
        # write your code below (just define function[s])
###############################################################################
# TODO
install(){
    cd "${this}"
    echo "Install fzf ..."
    #install binary
    # if [ ! -e $GOPATH/bin/fzf ];then
    #     cmd="go get -u github.com/junegunn/fzf"
    #     echo "$cmd ..."
    #     bash -c "$cmd > /dev/null" && { echo "Done"; } || { echo "Install fzf error!"; exit 1; }
    # fi

    # git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    if [ -d ~/.fzf ];then
        echo "~/.fzf exists,exit ..."
        exit
    fi

    # git clone --depth 1 https://gitee.com/quick-source/fzf.git ~/.fzf
    # ~/.fzf/install --all
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all

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

uninstall(){
  /bin/rm -rf ~/.fzf
  local output=/tmp/$$.fzf
  sed -e '/#BEGIN FZF function/,/#END FZF function/d' $home/.zshrc >"${output}"
  mv "${output}" $home/.zshrc
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
