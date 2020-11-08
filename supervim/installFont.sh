#!/bin/bash


installFont(){
    case $(uname) in
        "Linux")
            if fc-list | grep -iq Powerline;then
                return
            fi

            if [ ! -d ~/.local/share/fonts ];then
                mkdir -pv ~/.local/share/fonts
            fi
            cp ./fonts/PowerlineSymbols.otf ~/.local/share/fonts
            cp ./fonts/Droid\ Sans\ Mono\ for\ Powerline\ Nerd\ Font\ Complete.otf ~/.local/share/fonts
            fc-cache -vf ~/.local/share/fonts

            if [ ! -d ~/.config/fontconfig/conf.d ];then
                mkdir -pv ~/.config/fontconfig/conf.d
            fi
            cp ./fonts/10-powerline-symbols.conf ~/.config/fontconfig/conf.d
            ;;
        "Darwin")
            command -v brew >/dev/null 2>&1 || { echo "Need install homebrew first!"; exit 1; }
            if ! brew cask list font-hack-nerd-font>/dev/null 2>&1;then
                # brew tap caskroom/fonts old version
                brew tap homebrew/cask-fonts
                brew cask install font-hack-nerd-font
            fi
            echo "set Knack nerd font in iterm"
            ;;
        MINGW32*)
            echo "Please install nerd font manually."
            exit 1
            ;;
        *)
            echo "Unknown OS,install font failed!" >& 2
            exit 1
            ;;
    esac
}

installFont
