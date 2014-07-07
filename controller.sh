#!/bin/bash -x
# CONTROLLER



#Service Password: 548295a7ebf749b74d42
#
#Variables
KEYSTONE_DBPASS='364af2ed97cd57841f45'
DEMO_PASS='364af2ed97cd57841f45'
ADMIN_PASS='364af2ed97cd57841f45'
ADMIN_TOKEN='364af2ed97cd57841f45'
GLANCE_DBPASS='364af2ed97cd57841f45'
GLANCE_PASS='364af2ed97cd57841f45'
NOVA_DBPASS='364af2ed97cd57841f45'
NOVA_PASS='364af2ed97cd57841f45'
DASH_DBPASS='364af2ed97cd57841f45'
CINDER_DBPASS='364af2ed97cd57841f45'
CINDER_PASS='364af2ed97cd57841f45'
NEUTRON_DBPASS='364af2ed97cd57841f45'
NEUTRON_PASS='364af2ed97cd57841f45'

#MYSQL_PASS
MYSQL_PASS='364af2ed97cd57841f45'

ADMIN_EMAIL='admin@devtrax.com'

#Controller node
CONT_MNG='10.0.0.11'
CONT_TUN='10.0.1.11'

#Network node
NET_MNG='10.0.0.21'
NET_TUN='10.0.1.21'

#Computer node
COMP_MNG='10.0.0.31'
COMP_TUN='10.0.1.31'


#Notes:
#	Security:
#		MySQL - There should be a bind-addree configured in a production
#				enviroment, in practice this caused issues with MySQL
#				so this has been left disabled.
#		Qpid  - Authentication with qpid has been disabled for now to make
#				configuration simpiler. For EACH service:
#				qpid_username
#				qpid_password
#				More:
#					http://qpid.apache.org/releases/qpid-trunk/cpp-broker/book/chap-Messaging_User_Guide-Security.html
#
#	Network Config:
#		Managment Network:
#			Controller: 10.0.0.11
#			Network:	10.0.0.21
#			Compute 01:	10.0.0.31
#			Compute 02: 10.0.0.41
#			Compute 03: 10.0.0.51
#		Floating IPs:
#			NOT YET SET!
#		Tunnel Network:
#			Network:	10.0.1.21
#			Compute 01:	10.0.1.31
#			Compute 02: 10.0.1.41
#			Compute 03: 10.0.1.51
#		External Access:
#			Controller: 69.43.73.229
#			Network:	69.43.73.226
#			Compute 01:	69.43.73.227
#			Compute 02: 69.43.73.228
#			Compute 03: 69.43.73.???
#


#================================================ KEYSTONE Setup =========================================================== 
#Install keystone packages
yum install --enablerepo=epel openstack-keystone python-keystoneclient -y

#Configure keystone
openstack-config --set /etc/keystone/keystone.conf database connection mysql://keystone:$KEYSTONE_DBPASS@controller/keystone;
mysql -u root --password=$MYSQL_PASS -e "CREATE DATABASE keystone;"
mysql -u root --password=$MYSQL_PASS -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONE_DBPASS';"
mysql -u root --password=$MYSQL_PASS -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONE_DBPASS';"
#sync the database
su -s /bin/sh -c "keystone-manage db_sync" keystone


openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_token $ADMIN_TOKEN
keystone-manage pki_setup --keystone-user keystone --keystone-group keystone
chown -R keystone:keystone /etc/keystone/ssl
chmod -R o-rwx /etc/keystone/ssl

(crontab -l -u keystone 2>&1 | grep -q token_flush) || echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/keystone;


#start keyston service and enable at bootup
/sbin/service openstack-keystone restart
/sbin/chkconfig openstack-keystone on

#Keystone auth token
export OS_SERVICE_TOKEN=$ADMIN_TOKEN
export OS_SERVICE_ENDPOINT=http://controller:35357/v2.0

#Create Admin Account
keystone user-create --name=admin --pass=$ADMIN_PASS --email=$ADMIN_EMAIL
keystone role-create --name=admin
keystone tenant-create --name=admin --description="Admin Tenant"
keystone user-role-add --user=admin --tenant=admin --role=admin
keystone user-role-add --user=admin --role=_member_ --tenant=admin

#Create User Accounts
    #keystone user-create --name=demo --pass=DEMO_PASS --email=DEMO_EMAIL
    #keystone tenant-create --name=demo --description="Demo Tenant"
    #keystone user-role-add --user=demo --role=_member_ --tenant=demo

#Create Basic user Tenant
keystone tenant-create --name=basicuser --description="Basic User Tenant"

#Create account for Austin
keystone user-create --name=austin --pass=$ADMIN_PASS --email=austin@devtrax.com
keystone user-role-add --user=austin --role=_member_ --tenant=basicuser

#create account for Tim
keystone user-create --name=tim --pass=$ADMIN_PASS --email=tim@devtrax.com
keystone user-role-add --user=tim --role=_member_ --tenant=basicuser

#create account for Ryosuke
keystone user-create --name=morinor --pass=$ADMIN_PASS --email=morinor@devtrax.com
keystone user-role-add --user=morinor --role=_member_ --tenant=basicuser

#create account for Rey
keystone user-create --name=zhaox --pass=$ADMIN_PASS --email=zhaox@devtrax.com
keystone user-role-add --user=zhaox --role=_member_ --tenant=basicuser


#Create Service Tenant
keystone tenant-create --name=service --description="Service Tenant"

#Create service for Keystone
keystone service-create --name=keystone --type=identity --description="OpenStack Identity"

#Create endpoint for Keystone
keystone endpoint-create --service-id $(keystone service-list | grep identity | awk -F '|' '{print $2}') --publicurl=http://controller:5000/v2.0 --internalurl=http://controller:5000/v2.0 --adminurl=http://controller:35357/v2.0;

#Unload auth token
unset OS_SERVICE_TOKEN OS_SERVICE_ENDPOINT;

#set Admin Credential 
cp -f conf/temp.admin.sh /root/admin-openrc.sh
sed -i.org -e "s/ADMIN_PASS/$ADMIN_PASS/g" /root/admin-openrc.sh
source	/root/admin-openrc.sh



#================================================ Glance Setup ===========================================================
#Install Glance package
yum install --enablerepo=epel -y openstack-glance python-glanceclient

#Configure Glance
#Add location of Glance on the database
openstack-config --set /etc/glance/glance-api.conf database connection mysql://glance:$GLANCE_DBPASS@controller/glance
openstack-config --set /etc/glance/glance-registry.conf database connection mysql://glance:$GLANCE_DBPASS@controller/glance

#Configure the Image Service to use the message broker
openstack-config --set /etc/glance/glance-api.conf DEFAULT rpc_backend qpid
openstack-config --set /etc/glance/glance-api.conf DEFAULT qpid_hostname controller

#Create Glance DB
mysql -u root --password=$MYSQL_PASS -e "CREATE DATABASE glance;"
mysql -u root --password=$MYSQL_PASS -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$GLANCE_DBPASS';"
mysql -u root --password=$MYSQL_PASS -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$GLANCE_DBPASS';"
#sync database
su -s /bin/sh -c "glance-manage db_sync" glance

#Create Glance user for Keyston service
keystone user-create --name=glance --pass=$GLANCE_PASS --email=glance@devtrax.com
keystone user-role-add --user=glance --tenant=service --role=admin

#Configure Glance to use the Keystone for auth
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_host controller
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken admin_user glance
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken admin_password $GLANCE_PASS
openstack-config --set /etc/glance/glance-api.conf paste_deploy flavor keystone
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_host controller
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken admin_user glance;
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken admin_password $GLANCE_PASS
openstack-config --set /etc/glance/glance-registry.conf paste_deploy flavor keystone

#Create service for Glance
keystone service-create --name=glance --type=image --description="OpenStack Image Service"

#Create endpoint for Glance
keystone endpoint-create --service-id $(keystone service-list | grep -i image | awk -F '|' '{print $2}') --publicurl=http://controller:9292 --internalurl=http://controller:9292 --adminurl=http://controller:9292

#Set Glance service
service openstack-glance-api restart
service openstack-glance-registry restart
chkconfig openstack-glance-api on
chkconfig openstack-glance-registry on



#================================================ Nova Setup ===========================================================
#Install Nova packages
yum install --enablerepo=epel -y openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler python-novaclient 

#Add location of Nova on the database
openstack-config --set /etc/nova/nova.conf database connection mysql://nova:$NOVA_DBPASS@controller/nova
openstack-config --set /etc/nova/nova.conf DEFAULT rpc_backend qpid
openstack-config --set /etc/nova/nova.conf DEFAULT qpid_hostname controller

#Set my_ip, vncserver_listen and vncserver_proxycelient_address configs
openstack-config --set /etc/nova/nova.conf DEFAULT my_ip $CONT_MNG
openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_listen $CONT_MNG
openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address $CONT_MNG

#Create Nova database
mysql -u root --password=$MYSQL_PASS -e "CREATE DATASE NOVA;"
mysql -u root --password=$MYSQL_PASS -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'NOVA_DBPASS';"
mysql -u root --password=$MYSQL_PASS -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';"
#DB sync
su -s /bin/sh -c "nova-manage db sync" nova

#Create Nova user for the Keystone service
keystone user-create --name=nova --pass=$NOVA_PASS --email=nova@devtrax.com
keystone user-role-add --user=nova --tenant=service --role=admin

#Configure Nova to use the Keystone for Auth
openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_host controller
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_user nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_password $NOVA_PASS

#Create service for Nova
keystone service-create --name=nova --type=compute --description="OpenStack Compute"

#Create endpoint for Nova
keystone endpoint-create --service-id $(keystone service-list | grep -i compute | awk -F '|' '{print $2}') --publicurl=http://controller:8774/v2/%\(tenant_id\)s --internalurl=http://controller:8774/v2/%\(tenant_id\)s --adminurl=http://controller:8774/v2/%\(tenant_id\)s

#Set Nova services to run on boot
service openstack-nova-api restart
service openstack-nova-cert restart
service openstack-nova-consoleauth restart
service openstack-nova-scheduler restart
service openstack-nova-conductor restart
service openstack-nova-novncproxy restart
chkconfig openstack-nova-api on
chkconfig openstack-nova-cert on
chkconfig openstack-nova-consoleauth on
chkconfig openstack-nova-scheduler on
chkconfig openstack-nova-conductor on
chkconfig openstack-nova-novncproxy on



#================================================ Neutron Setup ===========================================================
#Create Neutron database
mysql -u root --password=$MYSQL_PASS -e "CREATE DATABASE neutron"
mysql -u root --password=$MYSQL_PASS -e "GRANT ALL PRIVILEDGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$NEUTRON_DBPASS';"
mysql -u root --password=$MYSQL_PASS -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$NEUTRON_DBPASS';"

#Create Neutron Users
keystone user-create --name neutron --pass $NEUTRON_PASS --email neutron@devtrax.com
keystone user-role-add --user neutron --tenant service --role admin

#Create Service for Neutron
keystone service-create --name neutron --type network --description "OpenStack Networking"

#Create endpoint for Neutron
keystone endpoint-create --service-id $(keystone service-list | grep -i network | awk -F '|' '{print $2}') --publicurl http://controller:9696 --adminurl http://controller:9696 --internalurl http://controller:9696

#Install Neutron packages
yum install --enablerepo=epel -y openstack-neutron openstack-neutron-ml2 python-neutronclient

#Configure Neutron
openstack-config --set /etc/neutron/neutron.conf database connection mysql://neutron:$NEUTRON_DBPASS@controller/neutron
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_host controller
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_user neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_password $NEUTRON_PASS

#Configure message broker
openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend neutron.openstack.common.rpc.impl_qpid
openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_hostname controller

#Configure Neutron to notify Nova about network topology change
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_url http://controller:8774/v2;
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_username nova
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_tenant_id $(keystone tenant-list | grep -i service | awk -F '|' '{ print $2 }')
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_password $NOVA_PASS
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_auth_url http://controller:35357/v2.0

#Configure Neutron to use the Modular Layer 2(ML2) plugin and associated services
openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins router

#Configure Modular Layer2 plugin
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers gre
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types gre
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_gre tunnel_id_ranges 1:1000
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group Truea

#Configure Nova to use Neutron
openstack-config --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_url http://controller:9696
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_auth_strategy keystone
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_tenant_name service
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_username neutron
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_password $NEUTRON_PASS
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_auth_url http://controller:35357/v2.0
openstack-config --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
openstack-config --set /etc/nova/nova.conf DEFAULT security_group_api neutron

# ONLY ON CONTROLLER node, Configure Compute node to use Metadata service
openstack-config --set /etc/nova/nova.conf DEFAULT service_neutron_metadata_proxy true
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_metadata_proxy_shared_secret $METADATA_SECRET
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

#Restart and set Neutron to start on boot
service openstack-nova-api restart
service openstack-nova-scheduler restart
service openstack-nova-conductor restart
service neutron-server restart
chkconfig neutron-server on

# Initial networks will be created later...



#================================================ Cidner Setup ===========================================================
#Install Cinder package
yum install -y openstack-cinder 

#Add location of Cinder on the database
openstack-config --set /etc/cinder/cinder.conf database connection mysql://cinder:$CINDER_DBPASS@controller/cinder

#Create Cidner DB
mysql -u root --password=$MYSQL_PASS -e "CREATE DATABASE cinder;"
mysql -u root --password=$MYSQL_PASS -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '$CINDER_DBPASS';"
mysql -u root --password=$MYSQL_PASS -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '$CINDER_DBPASS';"
#sync DB
su -s /bin/sh -c "cinder-manage db sync" cinder

#Create a Cinder user
keystone user-create --name=cinder --pass=$CINDER_PASS --email=cinder@devtrax.com
keystone user-role-add --user=cinder --tenant=service --role=admin

#Configure Cinder /etc/cinder/cinder.conf
openstack-config --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_host controller
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_user cinder
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_password $CINDER_PASS

#Configure Cinder to use message broker(QPID)
openstack-config --set /etc/cinder/cinder.conf DEFAULT rpc_backend cinder.openstack.common.rpc.impl_qpid
openstack-config --set /etc/cinder/cinder.conf DEFAULT qpid_hostname controller

#Create service for Cinder
keystone service-create --name=cinder --type=volume --description="OpenStack Block Storage"
#Create endpoint for Cinder
keystone endpoint-create --service-id$(keystone service-list | grep -i volume | awk -F '|' '{print $2}') --publicurl=http://controller:8776/v1/%\(tenant_id\)s --internalurl=http://controller:8776/v1/%\(tenant_id\)s --adminurl=http://controller:8776/v1/%\(tenant_id\)s

#Create service for Cinder version 2
keystone service-create --name=cinderv2 --type=volumev2 --description="OpenStack Block Storage v2"
#Create endpoint for Cinder version2
keystone endpoint-create --service-id $(keystone service-list | grep -i volumev2 | awk -F '|' '{print $2}') --publicurl=http://controller:8776/v2/%\(tenant_id\)s --internalurl=http://controller:8776/v2/%\(tenant_id\)s --adminurl=http://controller:8776/v2/%\(tenant_id\)s;

#restart service and set Cinder services to run on boot
service openstack-cinder-api restart
service openstack-cinder-scheduler restart
chkconfig openstack-cinder-api on
chkconfig openstack-cinder-scheduler on



#================================================ Horizon Setup ===========================================================
#install Horizon packages
yum install -y memcached python-memcached mod_wsgi openstack-dashboard 


#Configure dashboard /etc/openstack-dashboard/local_settings
# MAKE SURE  LOCATION value is exactly same as the /etc/sysconfig/memchased settings
#CACHES = {
#'default': {
#'BACKEND' : 'django.core.cache.backends.memcached.MemcachedCache',
#'LOCATION' : '127.0.0.1:11211'
#}
#}

#Enable accessing dashboard from anywhere 
# ALLOWED_HOSTS = ['*'] 

/bin/sed -i.org -e "s/OPENSTACK_HOST = \"[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}\"/OPENSTACK_HOST = \"controller\"/"  /etc/openstack-dashboard/local_settings
/bin/sed -i.org "14i\ALLOWED_HOSTS = [\'\*\']" /etc/openstack-dashboard/local_settings


#add SELinux Policy
setsebool -P httpd_can_network_connect on

service httpd restart
service memcached restart
chkconfig httpd on
chkconfig memcached on


#SWIFT?
