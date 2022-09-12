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

install(){
    _require_command git curl
    set -xe

    # install omz
    (
        cd /tmp
        local installer="omzInstaller-$(date +%s).sh"
        curl -fsSL -o ${installer} https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh
        RUNZSH=no bash ${installer}
        ln -sf ${PWD}/zshrc ~/.zshrc
    )

    # omz plugins
    # zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions

    # custom theme
    ln -sf ${PWD}/*.zsh-theme ${ZSH_CUSTOM}/themes

    # sed -ibak \
    #     -e 's/\(ZSH_THEME=\).\{1,\}/\1"zeta"/' \
    #     -e 's/plugins=.*/plugins=(git cp themes timer sudo dirhistory golang rust npm yarn zsh-autosuggestions)/' \
    #     ~/.zshrc
    # rm ~/.zshrcbak

    # zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
    # echo "source ~/.zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc

 #    startLine="##CUSTOM BEGIN v3"
 #    endLine="##CUSTOM END v3"
 #    configFile=~/.zshrc
 #    export SHELLRC_ROOT=${this}
 #    if ! grep -q "$startLine" "${configFile}";then
 #        cat <<-EOF >> "$configFile"
	# $startLine
	# export SHELLRC_ROOT=${this}
	# source \${SHELLRC_ROOT}/shellrc
	# $endLine
	# EOF
 #    fi
 #    echo "bindkey ',' autosuggest-accept" >> ~/.zshrc

    if [ ! -e "$HOME/.editrc" ] || ! grep -q 'bind -v' "$HOME/.editrc";then
        echo 'bind -v' >> "$HOME/.editrc"
    fi
    if [ ! -e "$HOME"/.inputrc ] || ! grep -q 'set editing-mode vi' "$HOME/.inputrc";then
        echo 'set editing-mode vi' >> "$HOME/.inputrc"
    fi

    # soft link sshconfig
    [ ! -d ~/.ssh ] && mkdir ~/.ssh
    ln -sf ${SHELLRC_ROOT}/shellrc.d/sshconfig $HOME/.ssh/config
}

uninstall(){
    set -x
    cp ~/.zshrc{,.old}
    /bin/rm -rf ~/.zshrc
    /bin/rm -rf ~/.oh-my-zsh
    /bin/rm -rf ~/.zsh-syntax-highlighting
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
