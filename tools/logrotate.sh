#!/bin/bash
rpath="$(readlink ${BASH_SOURCE})"
if [ -z "$rpath" ];then
    rpath=${BASH_SOURCE}
fi
thisDir="$(cd $(dirname $rpath) && pwd)"
cd "$thisDir"

user="${SUDO_USER:-$(whoami)}"
home="$(eval echo ~$user)"

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
cyan=$(tput setaf 5)
        bold=$(tput bold)
reset=$(tput sgr0)
function runAsRoot(){
    verbose=0
    while getopts ":v" opt;do
        case "$opt" in
            v)
                verbose=1
                ;;
            \?)
                echo "Unknown option: \"$OPTARG\""
                exit 1
                ;;
        esac
    done
    shift $((OPTIND-1))
    cmd="$@"
    if [ -z "$cmd" ];then
        echo "${red}Need cmd${reset}"
        exit 1
    fi

    if [ "$verbose" -eq 1 ];then
        echo "run cmd:\"${red}$cmd${reset}\" as root."
    fi

    if (($EUID==0));then
        sh -c "$cmd"
    else
        if ! command -v sudo >/dev/null 2>&1;then
            echo "Need sudo cmd"
            exit 1
        fi
        sudo sh -c "$cmd"
    fi
}
###############################################################################
# write your code below (just define function[s])
# function with 'function' is hidden when run help, without 'function' is show
###############################################################################
# TODO
if [ -n "${LOCAL_APP_ROOT}" ];then
    prefix=${LOCAL_APP_ROOT}
else
    prefix=$HOME/.local/apps
fi
install(){
    if ! command -v logrotate >/dev/null 2>&1;then
        echo "Need logrotate installed!"
        exit 1
    fi
    local dest=${prefix}/logrotate
    local confDir=conf.d
    echo "logrotate dest: $dest"
    if [ ! -d "$dest/$confDir" ];then
        echo "mkdir $dest/$confDir..."
        mkdir -p $dest/$confDir
    fi
    cat<<EOF > ${dest}/logrotate.conf
#/tmp/testfile.log {
    #weekly | monthly | yearly
    # Note: size will override weekly | monthly | yearly
    #size 100k # | size 200M | size 1G

    #rotate 3
    #compress

    # Note: copytruncate conflics with create
    # and copytruncate works well with tail -f,create not works well with tail -f
    #create 0640 user group
    #copytruncate

    #su root root
#}
include ${dest}/$confDir
EOF
    cat<<EOF2
Tips:
    add settings to ${dest}/$confDir
    use logrotate -d ${dest}/logrotate.conf to check configuration file syntax
    add "/path/to/logrotate -s ${dest}/status ${dest}/logrotate.conf" to crontab(Linux) or launchd(MacOS)
EOF2

    case $(uname) in
        Darwin)
            cat<<EOF3>$home/Library/LaunchAgents/mylogrotate.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>mylogrotate</string>
    <key>WorkingDirectory</key>
    <string>/tmp</string>
    <key>ProgramArguments</key>
    <array>
        <string>$(which logrotate)</string>
        <string>-s</string>
        <string>${dest}/status</string>
        <string>${dest}/logrotate.conf</string>
    </array>
    <key>StandardOutPath</key>
    <string>/tmp/mylogrotate.out</string>
    <key>StandardErrorPath</key>
    <string>/tmp/mylogrotate.err</string>
    <key>RunAtLoad</key>
    <true/>

    <!--
        start job every 300 seconds
    -->
    <key>StartInterval</key>
    <integer>300</integer>

    <!--
        crontab like job schedular
    -->
    <!--
    <key>StartCalendarInterval</key>
    <dict>
        <key>Minute</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>0</integer>
        <key>Day</key>
        <integer>0</integer>
        <key>Weekday</key>
        <integer>0</integer>
        <key>Month</key>
        <integer>0</integer>
    </dict>

    -->
</dict>
</plist>
EOF3
            ;;
        Linux)
            (crontab -l 2>/dev/null;echo "*/10 * * * * $(which logrotate) -s ${dest}/status ${dest}/logrotate.conf")|crontab -
            ;;
    esac
}



###############################################################################
# write your code above
###############################################################################
function help(){
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
