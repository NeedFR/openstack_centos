#!/bin/bash -x

#openstack
#basic installation



#------------VARIABLE------------
ARC=$(/bin/uname -m)

OS=$(cat /etc/redhat-release | awk -F ' ' '{print $1}')
VERSION=$(cat /etc/redhat-release | awk -F ' ' '{print $3}')
VER_REQ='6.5'

##TEXT COLOR
COLOR_LIGHT_GREEN='\033[1;32m'
COLOR_LIGHT_BLUE='\033[1;34m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
COLOR_WHITE='\033[1;37m'
COLOR_DEFAULT='\033[0m'

##----------PREPARATION-----------

#Check ROOT permission
if [[ $UID != 0 ]]; then
    echo -e "${COLOR_RED}Please run this script as root or sudo!${COLOR_DEFAULT}"
    exit 1
else
    echo -e "${COLOR_LIGHT_BLUE}ROOT/SUDO run\t\t\t${COLOR_LIGHT_GREEN}[OK]${COLOR_DEFAULT}"
    #Check OS version
    if [ $VERSION != $VER_REQ ] ; then
        echo -e  "${COLOR_RED}OS must be CentOS 6.5${COLOR_DEFAULT}"
        echo -e "${COLOR_LIGHT_GREEN}$OS, $VERSION${COLOR_DEFAULT}"
        exit 2
    else
        echo -e "${COLOR_LIGHT_BLUE}OS version\t\t\t${COLOR_LIGHT_GREEN}[OK]${COLOR_DEFAULT}"
        #Check system machine architectre
        if [ $ARC != 'x86_64' ]; then
            echo -e "${COLOR_RED}$ARC i386 compatible"
            echo "This program is only capable for x64 systems${COLOR_DEFAULT}"
            exit 3
        else
            echo -e "${COLOR_LIGHT_BLUE}System Architecture\t\t${COLOR_LIGHT_GREEN}[OK]${COLOR_DEFAULT}"

#generate keys
#openssl rand -hex 10

            ## add EPEL repo
            /bin/rpm --import http://ftp.riken.jp/Linux/fedora/epel/RPM-GPG-KEY-EPEL-6
            /bin/rpm -ivh http://ftp.riken.jp/Linux/fedora/epel/6/${ARC}/epel-release-6-8.noarch.rpm
            /bin/sed -i.org -e "s/enabled.*=.*1/enabled=1/g" /etc/yum.repos.d/epel.repo

            #add RDO Icehouse repo
            #/usr/bin/yum install -y http://rdo.fedorapeople.org/rdo-release.rpm

            #install ntp
            /usr/bin/yum install -y ntp
            /usr/sbin/ntpdate server 0.centos.pool.ntp.org
            /sbin/chkconfig ntpd on
            /sbin/service ntpd restart

            #sshd config | allow root login
            /bin/sed -i.org -e 's/PermitRootLogin no/PermitRootLogin yes/gi' /etc/ssh/sshd_config
            /sbin/service sshd reload

            #mysqls install
            /usr/bin/yum install -y mysql mysql-server MySQL-python
            /sbin/chkconfig mysqld on
            /sbin/server mysqld restart


            #update package
            /usr/bin/yum -y update

            echo -e "${COLOR_LIGHT_BLUE}Inital configuration is done.${COLOR_DEFAULT}"
            echo -e "${COLOR_RED}Please reboot the system to apply all of the configuration${COLOR_DEFAULT}"

        fi #OS version check
    fi #system arch check
fi #root check
