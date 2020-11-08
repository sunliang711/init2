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

rpath="$(readlink ${BASH_SOURCE})"
if [ -z "$rpath" ];then
    rpath=${BASH_SOURCE}
fi
thisScriptDir="$(cd $(dirname $rpath) && pwd)"


cp ${thisScriptDir}/coc-settings.json $vimroot


if ! npm list -g 2>/dev/null | grep neovim >/dev/null 2>&1 ;then
    echo "coc need neovim module in npm, install it..."
    npm install -g neovim >/dev/null 2>&1 || { echo "${red}Warning${reset}: Install neovim by npm failed.Please install it with sudo privilege manaually."; }
fi

if ! command -v cmake-language-server >/dev/null 2>&1;then
    echo "No cmake-language-server in python module, install it..."
    pip3 install --user cmake-language-server >/dev/null 2>&1 || { echo "${red}Warning${reset}:Please use pip3 to install cmake-language-server"; }
fi


if ! command -v bash-language-server >/dev/null 2>&1;then
    echo "No bash-language-server, install it ..."
    npm install -g bash-language-server >/dev/null 2>&1 || { echo "${red}Warning${reset}:Please use npm to install bash-language-server"; }
fi

if ! command -v clangd >/dev/null 2>&1;then
    echo "${green}Recommend${reset}: install ${bold}clangd${reset} as C/C++ language server when needed. Clangd usually belongs to clang package or llvm package. "
fi

echo "${cyan}Install coc-snippets..."
echo "please run $VIM -c 'CocInstall coc-snippets' -c 'qall!' manaually!"

echo "${green}Recommend${reset}: install coc-python plugin by 'CocInstall coc-python' if you need."
echo "${green}Recommend${reset}: install coc-rls plugin by 'CocInstall coc-rls' if you need."
echo "${red}NOTE${reset} disable npm registry before run 'CocInstall' command !!"
