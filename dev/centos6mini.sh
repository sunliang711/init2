centos 6.8 mini:
##1
#sed -i 's/ONBOOT=no/ONBOOT=yes/' /etc/sysconfig/network-scripts
#reboot

##2
yum update -y

##3 install gui
yum groupinstall -y "Desktop"
yum groupinstall -y "Desktop Platform"
yum groupinstall -y "X Window System"
yum groupinstall -y "Fonts"
yum groupinstall -y "General Purpose Desktop"

yum groupinstall -y "Development Tools"

yum install -y kernel-devel
yum install -y kernel-headers
yum install -y ncurses-devel
yum install -y boost-devel

yum install -y man
yum install -y vim
yum install -y python-devel
yum install -y cmake
