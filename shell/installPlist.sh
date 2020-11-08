#!/bin/bash

#pwd must exist bin/

#pwd can exist etc/ [optional]

check(){
    [ -d bin ] || { echo "bin/ doesn't exist!"; exit 1; }
    [ "$(ls -A bin)" ] || { echo "nothing in bin/"; exit 1; }
    user=${SUDO_USER:-$(whoami)}
    home=$(eval echo ~$user)

    cat<<EOF
user: $user
home: $home
EOF
}


#install need change to original privilege
#plist need change to root privilege
#service need change to root privilege
install(){
    if [ $# -lt 1 ];then
        echo 'install cmd need "name" argument'
        exit 1
    fi
    check
    name=$1
    echo "name: $name"
    root=$home/.$name
    echo "root: $root"
    echo "Copying bin/ to $root..."

    if [ -d "$root" ];then
        echo "$root exists,override it? [y/n] "
        read over
        if [ "$over" == "y" ];then
            rm -rf "$root"
        else
            exit 1
        fi
    fi
    mkdir -p "$root"

    cp -R bin "$root"
    [ -d etc ] && { echo "Copying etc to $root";cp -R etc "$root"; }
    echo "Mkdir run"
    mkdir -p "$root/run"
}

plist(){
    cat>$home/Library/LaunchAgents/local.$name.plist<<EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    <key>Label</key>
    <string>local.$name</string>
    <key>ProgramArguments</key>
    <array>
    <string>$root/bin/$name</string>
    </array>
    <key>StandardOutPath</key>
    <string>$root/run/stdout</string>
    <key>StandardErrorPath</key>
    <string>$root/run/stderr</string>
    <key>RunAtLoad</key>
    <true/>
    </dict>
    </plist>
EOF
}
service(){
    cat>/etc/systemd/system/local.$name.service<<EOF
    [Unit]
    Description= $name service
    #After=network.target

    [Service]
    #Type=forking
    #PIDFile=
    #ExecStart=
    #ExecStop=

    #Type=oneshot
    #RemainAfterExit=yes
    #ExecStart=
    #ExecStop=

    Type=simple
    ExecStart=$root/bin/$name
    #ExecStop=

    #Environment=
    [Install]
    WantedBy=multi-user.target
EOF
}
autoBoot(){
    #TODO root privilege check
    case $(uname) in
        Darwin)
            plist
            ;;
        Linux)
            if [ $EUID -ne 0 ];then
                sudo service || { echo "You don't have sudo privilege or something else."; exit 1; }
            else
                service
            fi
            ;;
    esac
}
perm(){
    if [ -n ${SUDO_USER} ];then
        chown -R $user "$root"
    fi
}

usage(){
    cat<<EOF
Usage: $(basename $0) cmd

cmd:
    install <name>
    uninstall
    usage
EOF
}
case $1 in
    install)
        install $2
        autoBoot
        perm
        ;;
    uninstall)
        #TODO
        echo "uninstall not complete"
        ;;
    *)
        usage
        ;;
esac
