#!/usr/bin/env bash

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
installRootDir="$(cd $(dirname $rpath) && pwd)"
cd "$installRootDir"

usage(){
    cat<<EOF
Usage: $(basename $0) ${bold}CMD${reset}

${bold}CMD${reset}:
    install   [options] <vim/nvim>
    uninstall [options] <vim/nvim>
    font

options:
        -f              install nerd font used by color theme
        -o              install plugin from original source(github.com),instead of gitee.com
        -u              update basic setting
EOF
exit 1
}

needCmd(){
    local cmd=$1
    if [[ -n $cmd ]];then
        if ! command -v $cmd >/dev/null 2>&1;then
            echo "Error: Need cmd \"$cmd\"!!"
            exit 1
        fi
    fi
}

installDir(){
    if [ ! -d "$2" ];then
        mkdir -p "$2"
    fi

    if [ -d "$1" ];then
        echo "copy $1 -> $2..."
        cp -r "$1" "$2"
    fi
}


install(){
    cat<<EOF
Note:   install nodejs pip3 golang fzf when need
        setup pip3 source and npm source when need.
        press ${red}<C-c>${reset} to break if you haven't installed above
        press ${red}<Enter>${reset} to continue...
EOF
    read cnt

    cat msg

    font=0
    origin=0
    vimroot=
    cfg=
    update=0


    while getopts ":fou" opt;do
        case $opt in
            f)
                font=1
                ;;
            o)
                origin=1
                ;;
            u)
                update=1
                ;;
            :)
                echo "Option '$OPTARG' need argument"
                exit 1
                ;;
            \?)
               echo "Unknown option: '$OPTARG'"
                exit 1
                ;;
        esac
    done
    shift $((OPTIND-1))

    needCmd curl

    VIM=$1
    case $VIM in
        nvim)
            needCmd nvim
            vimroot="$HOME/.config/nvim"
            cfg="$vimroot/init.vim"
            ;;
        vim)
            needCmd vim
            vimVersion=$(vim --version | head -1 | awk '{print $5}')
            vimroot="$HOME/.vim"
            major=$(echo $vimVersion | awk -F. '{print $1}')
            minor=$(echo $vimVersion | awk -F. '{print $2}')
            if [[ -z $major ]] || [[ -z $minor ]];then
                echo "Cannot get vim version!"
                exit 1
            fi
            if (( $major == 7 && $minor >= 4 )) || (( $major > 7 ));then
                cfg="$vimroot/vimrc"
            else
                cfg="$HOME/.vimrc"
            fi
            ;;
        *)
            echo "Choose vim or nvim as argument."
            usage
            ;;
    esac

    if (( $update==1 ));then
        echo "update basic-pre.vim..."
        cp ./basic-pre.vim $vimroot/
        exit 0
    fi
    if [ "$font" -eq "1" ];then
        bash ./installFont.sh || { echo "Install font error."; }
    fi

    installDir colors "$vimroot"

    ## Download vim-plug
    if (($origin==1));then
        echo  "Downloading vim-plug from github..."
        curl -fLo $vimroot/autoload/plug.vim --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim || { echo "download vim-plug failed.";uninstall; exit 1; }
    else

        echo  "Downloading vim-plug from gitee..."
        echo "$(tput setaf 1)Make sure not use git proxy!!$(tput sgr0)"
        curl -fLo $vimroot/autoload/plug.vim --create-dirs \
            https://gitee.com/quick-source/vim-plug/raw/master/plug.vim || { echo "download vim-plug failed.";uninstall; exit 1; }
    fi


    echo "copy file: basic-pre.vim -> $vimroot"
    cp ./basic-pre.vim $vimroot/

    echo "copy file: basic-post.vim -> $vimroot"
    cp ./basic-post.vim $vimroot/

    ### header
    echo "copy file content: init-header.vim -> $cfg"
    cat ./init-header.vim > $cfg

    ### display menu for user to choose which plugins to be installed
    pluginsDir="plugins-available"
    echo "All available plugins are in ${pluginsDir}"
    ## 动态生成可供选择安装的插件菜单
    userChoiceFile="/tmp/vim-plugin-install-menu"
    echo "## Set plugin name to 1 to install it." > ${userChoiceFile}
    echo "Enter plugins dir: $pluginsDir"
    cd ${pluginsDir}
    while read -r dir;do
        #pluginName is dirname
        dirname=${dir#./}
        echo "Enter plugin dir: $dirname"
        cd "$dirname"
        pluginName=$dirname
        if [ ! -e default ];then
            echo "Error: plugin: $pluginName no default file"
            exit 1
        fi
        pluginDefault=$(cat default)

        printf "%-25s = %s\n" ${pluginName} ${pluginDefault} >> ${userChoiceFile}

        cd ..
    done <<< "$(find . -maxdepth 1 ! -path . -type d)"
    #TODO when failed,check bash version must 4+

    $VIM ${userChoiceFile}

    declare -a toBeInstalledPlugins
    # vimrc (init.vim) plugin item
    while read -r line;do
         if echo "$line" | grep -q '^[ \t]*#';then
            # ignore comment
             continue
         fi

        enable=$(echo "$line" | perl -ne 'print $1 if /^\s*(\S+)\s*=\s*1\s*$/')
        if [ -n "$enable" ];then
            toBeInstalledPlugins+=("$enable")
        fi
    done < "${userChoiceFile}"
    rm ${userChoiceFile}

    echo "--------------------After user choice---------------------------"

    while read -r dir;do
        #pluginName is dirname
        dirname=${dir#./}
        pluginName=$dirname
        if ! printf "%s\n" ${toBeInstalledPlugins[@]} | grep -q "$pluginName";then
            #skip
            continue
        fi

        echo "Enter plugin dir: $dirname"
        cd "$dirname"

        #2. get plugin path
        # pluginPath=`perl -ne 'print if /PATH BEGIN/.../PATH END/' path | sed -e '1d;$d'`
        pluginPath=`cat path`
        if (($origin==1));then
            echo "$pluginPath" >> $cfg
        else
            echo "$pluginPath" | perl -pe "s|(Plug ')[^/]+(/.+)|\1https://gitee.com/quick-source\2|" >> "$cfg"
        fi
        cd ..
    done <<< "$(find . -maxdepth 1 ! -path . -type d)"

    echo "call plug#end()" >> "$cfg"
    echo  >> "$cfg"

    echo "${bold}${cyan}Install plugins...${reset}"
    $VIM -c PlugInstall -c qall

    # Note VIMRUNTIME is important when executing vim command in shell
    if [ "$VIM" = "vim" ];then
        export VIMRUNTIME="`vim -e -T dumb --cmd 'exe "set t_cm=\<C-M>"|echo $VIMRUNTIME|quit' | tr -d '\015' `"
    elif [ "$VIM" = "nvim" ];then
        export VIMRUNTIME="`nvim --clean --headless --cmd 'echo $VIMRUNTIME|q' 2>&1`"
    fi
    echo "${cyan}VIMRUNTIME:${reset} ${VIMRUNTIME}"

    while read -r dir;do
        #pluginName is dirname
        dirname=${dir#./}
        pluginName=$dirname

        if ! printf "%s\n" ${toBeInstalledPlugins[@]} | grep -q "$pluginName";then
            #skip
            continue
        fi
        echo "Enter plugin dir: $dirname"
        cd "$dirname"

        cat<<cfgEOF >>"$cfg"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""      Begin $pluginName config
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
cfgEOF
        cat config >> "$cfg"

        cat<<cfgEOFx >>"$cfg"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""      End $pluginName config
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
cfgEOFx
        cd ..
    done <<< "$(find . -maxdepth 1 ! -path . -type d)"


    echo "${bold}${cyan}Done.${reset}"

    # export VIM,vimroot,installRootDir for script use
    export VIM
    export vimroot
    export installRootDir

    ## SCRIPT
    echo "${bold}${cyan}Run post scripts...${reset}"
    while read -r dir;do
        #pluginName is dirname
        dirname=${dir#./}
        pluginName=$dirname

        if ! printf "%s\n" ${toBeInstalledPlugins[@]} | grep -q "$pluginName";then
            #skip
            continue
        fi
        echo "Run post script in: $dirname"
        cd "$dirname"

        #2. run plugin script
        [ -e postScript.sh ] && bash postScript.sh

        cd ..
    done <<< "$(find . -maxdepth 1 ! -path . -type d)"


    ## restore PWD
    cd ${installRootDir}


    echo "copy file content: init-tailer.vim -> $cfg"
    cat init-tailer.vim >> "$cfg"

    echo "${bold}${cyan}Done.${reset}"

}

uninstall(){
    echo "TODO"
}

cmd=$1
shift
case $cmd in
    install)
        install "$@"
        ;;
    uninstall)
        uninstall "$@"
        ;;
    font)
        bash ./installFont.sh
        ;;
    *)
        usage
        ;;
esac
