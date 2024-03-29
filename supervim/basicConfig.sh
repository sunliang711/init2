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
# function is hidden when begin with '_'

globalVimrcPath=/etc/vim
userVimrcPath=$home

vimGlobal(){
    _require_root

    if [ ! -d ${globalVimrcPath} ];then
        mkdir -pv ${globalVimrcPath}
    fi

    if [ -e ${globalVimrcPath}/vimrc.local ];then
        echo "already exists ${globalVimrcPath}/vimrc.local, skip.."
        return 0
    fi

    echo "install vimrc to ${globalVimrcPath}.."
    dest=${globalVimrcPath}/vimrc.local
    sed -ne '1,/"vim-plug/p' ${this}/basic-pre.vim > ${dest}
}

vimUser(){
    if [ -e ${userVimrcPath}/.vimrc ];then
        echo "already exists ${userVimrcPath}/.vimrc, skip.."
        return 0
    fi

    echo "install vimrc to ${userVimrcPath}.."
    dest=${userVimrcPath}/.vimrc
    sed -ne '1,/"vim-plug/p' ${this}/basic-pre.vim > ${dest}
}

userNvimrcPath=$home/.config/nvim
nvim(){

    if [ ! -d ${userNvimrcPath} ];then
        mkdir -pv ${userNvimrcPath}
    fi

    if [ -e ${userNvimrcPath}/init.vim ];then
        echo "already exists ${userNvimrcPath}/init.vim skip.."
        return 0
    fi
    echo "install vimrc to ${userNvimrcPath}/init.vim.."
    dest=${userNvimrcPath}/init.vim
    sed -ne '1,/"vim-plug/p' ${this}/basic-pre.vim > ${dest}

}

# write your code above
###############################################################################

em(){
    $ed $0
}

function _help(){
    cd "${this}"
    cat<<EOF2
Usage: $(basename $0) ${bold}CMD${reset}

${bold}CMD${reset}:
EOF2
    perl -lne 'print "\t$2" if /^\s*(function)?\s*(\S+)\s*\(\)\s*\{$/' $(basename ${BASH_SOURCE}) | perl -lne "print if /^\t[^_]/"
}

case "$1" in
     ""|-h|--help|help)
        _help
        ;;
    *)
        "$@"
esac
