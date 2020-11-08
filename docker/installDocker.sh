#!/bin/bash

if [ $EUID != 0 ];then
    echo "Need run as root"
    exit 1
fi
version=19.03.4
url="https://download.docker.com/linux/static/stable/x86_64/docker-${version}.tgz"

(cd /tmp && curl -LO "$url" && tar xvf docker-${version}.tgz && cp docker/* /usr/local/bin)

cp docker.service /etc/systemd/system
[ ! -d /etc/docker ] && mkdir /etc/docker
cp daemon.json /etc/docker
