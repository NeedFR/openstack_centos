#!/bin/bash -x

#openstack
#basic installation

#generate keys
#openssl rand -hex 10
KEYSTONE_DBPASS='364af2ed97cd57841f45'
DEMO_PASS=''
ADMIN_PASS='364af2ed97cd57841f45'
GLANCE_DBPASS='364af2ed97cd57841f45'
GLANCE_PASS='364af2ed97cd57841f45'
NOVA_PASS='364af2ed97cd57841f45'
DASH_DBPASS='364af2ed97cd57841f45'
CINDER_DBPASS='364af2ed97cd57841f45'
CINDER_PASS='364af2ed97cd57841f45'
NEUTRON_DBPASS='364af2ed97cd57841f45'
NEUTRON_PASS='364af2ed97cd57841f45'
TROVE_DBPASS='364af2ed97cd57841f45'
TROVE_PASS='364af2ed97cd57841f45'


MYSQL_PASS='364af2ed97cd57841f45'

#Dashboard admin password
PASS='admin'

#NIC
NIC1='eth1'     #PUBLIC NETWORK NIC
NIC2='eth2'     #PRIVATE NETWORK NIC

#Static IP
#IPADDR='192.168.1.244'
#NETMASK='255.255.255.0'
#GATEWAY='192.168.1.1'

#Network
#   eth0 - internet
#   eth1 - managmenet   10.0.0.0/24
#   eth2 - tunnel       10.0.1.0/24



#Controller node
CONT_MNG='10.0.0.11'
CONT_TUN='10.0.1.11'

#Network node
NET_MNG='10.0.0.21'
NET_TUN='10.0.1.21'

#Computer node
COMP_MNG='10.0.0.31'
COMP_TUN='10.0.1.31'



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

            ## Disable SELINUX
            /usr/sbin/setenforce 0
            /bin/sed -i.org -e 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
    
            ## Edit Kernel Parameter to enable Routing
            #change curernt parameter
            /bin/echo '1' > /proc/sys/net/ipv4/ip_forward
            /bin/echo '0' > /proc/sys/net/ipv4/conf/default/rp_filter
    
            #edit sysctl.conf
            /bin/sed -i.org -e 's/net.ipv4.ip_forward = 0/net.ipv4_ip_forward = 1/g' /etc/sysctl.conf
            /bin/sed -i.org -e 's/net.ipv4.conf.default.rp_filter = 1/net.ipv4.conf.default.rp_filter = 0/g' /etc/sysctl.conf
    
            #add more variable
            /bin/cat << _SYSCTLCONF_ >> /etc/sysctl.conf
            net.ipv4.conf.all.rp_filter = 0
            net.ipv4.conf.all.forwarding = 1
_SYSCTLCONF_

    
#            #edit /etc/rc.local
#            /bin/echo 'echo 0 > /proc/sys/net/bridge/bridge-nf-call-iptables' >> /etc/rc.local
#            /bin/echo 'echo 0 > /proc/sys/net/bridge/bridge-nf-call-ip6tables' >> /etc/rc.local
#            /bin/echo 'echo 0 > /proc/sys/net/bridge/bridge-nf-call-arptables' >> /etc/rc.local
    
            /sbin/sysctl -p /etc/sysctl.conf


            ## add EPEL repo
            /bin/rpm --import http://ftp.riken.jp/Linux/fedora/epel/RPM-GPG-KEY-EPEL-6
            /bin/rpm -ivh http://ftp.riken.jp/Linux/fedora/epel/6/${ARC}/epel-release-6-8.noarch.rpm
            /bin/sed -i.org -e "s/enabled.*=.*0/enabled=1/g" /etc/yum.repos.d/epel.repo

            #install ntp
            /usr/bin/yum install -y ntp
            /usr/sbin/ntpdate 0.centos.pool.ntp.org
            /sbin/chkconfig ntpd on
            /sbin/service ntpd restart

            #sshd config | allow root login
            /bin/sed -i.org -e 's/PermitRootLogin no/PermitRootLogin yes/gi' /etc/ssh/sshd_config
            /sbin/service sshd reload

            #install mysql client/server MySQL-python
            /usr/bin/yum install -y mysql mysql-server MySQL-python
            /sbin/chkconfig mysqld on
            /sbin/service mysqld restart
            case "$OS" in
                "Fedora") cp -f conf/my.cnf.fed /etc/my.cnf ;;
                "CentOS") cp -f conf/my.cnf.cent /etc/my.cnf ;;          
            esac
            sed -i "2i\bind-address = $CONT_MNG" /etc/my.cnf            

            #Allow aceess globaly
            mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_PASS' WITH GRANT OPTION;"

            #change root password 
            mysql -u root -e "UPDATE mysql.user SET Password = PASSWORD('$MYSQL_PASS') WHERE User = 'root';"
            mysql -u root -e "FLUSH PRIVILEGES;"
            /sbin/chkconfig mysqld on
            /sbin/service mysqld restart

            #install QPID message server
            /usr/bin/yum install -y qpid-cpp-server
            /sbin/chkconfig qpidd on
            /sbin/service qpidd restart
            /bin/sed -i.org -e 's/auth=yes/auth=no/g' /etc/qpidd.conf
            
            #install RDO Icehouse
            #/usr/bin/yum install yum-plugin-priorities
            /usr/bin/yum install -y http://rdo.fedorapeople.org/rdo-release.rpm
            /usr/bin/yum install -y openstack-utils

            #upgrade package
         #   /usr/bin/yum -y upgrade

            echo -e "${COLOR_LIGHT_BLUE}Inital configuration is done.${COLOR_DEFAULT}"
            echo -e "${COLOR_RED}Please reboot the system to apply all of the configuration${COLOR_DEFAULT}"

        fi #OS version check
    fi #system arch check
fi #root check
