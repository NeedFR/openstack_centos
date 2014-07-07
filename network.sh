#!/bin/bash -x
#
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
#	Initial Setup:
#		yum install ntp MySQL-python yum-plugin-priorities http://repos.fedorapeople.org/repos/openstack/openstack-icehouse/rdo-release-icehouse-3.noarch.rpm http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm openstack-utils openstack-selinux qpid-cpp-server -y;
#		yum upgrade -y;
#		reboot
#		service ntpd start;
#		chkconfig ntpd on;
#		service qpidd start;
#		chkconfig qpidd on
#
#	Kernel functions:
#		/etc/sysctl.conf
#			net.ipv4.ip_forward=1
#			net.ipv4.conf.all.rp_filter=0
#			net.ipv4.conf.default.rp_filter=0
# 		sysctl -p
#	Hosts:
#		add 'controller' to host with the management IP

#We recommend adding verbose = True to the [DEFAULT] section in /etc/neutron/neutron.conf to assist with troubleshooting.

#================================================Neutron  Setup =========================================================== 

## Edit Kernel Parameter to enable Routing
#change curernt parameter
#/bin/echo '1' > /proc/sys/net/ipv4/ip_forward
#/bin/echo '0' > /proc/sys/net/ipv4/conf/default/rp_filter
#
##edit sysctl.conf
#/bin/sed -i.org -e 's/net.ipv4.ip_forward = 0/net.ipv4_ip_forward = 1/g' /etc/sysctl.conf
#/bin/sed -i.org -e 's/net.ipv4.conf.default.rp_filter = 1/net.ipv4.conf.default.rp_filter = 0/g' /etc/sysctl.conf
#
#/bin/cat << _SYSCTLCONF_ >> /etc/sysctl.conf
#net.ipv4.conf.all.rp_filter = 0
#net.ipv4.conf.all.forwarding = 1
#_SYSCTLCONF_
#Apply all change
# /sbin/sysctl -p /etc/sysctl.conf


#install neutron packages
yum install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch



#Configure Keystone for Neutron node
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_host controller
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_user neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_password $NEUTRON_PASS

#Configure Neutron Message server
openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend neutron.openstack.common.rpc.impl_qpid
openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_hostname controller

#Add Modular Layer2 (ML2) plugin
openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins router

#Add L3 agent to provide routing services for instance virtual network
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT use_namespaces True

#Add DHCP agent
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT use_namespaces True

#Add Metadata agent
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT auth_url http://controller:5000/v2.0
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT auth_region regionOne
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_tenant_name service
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_user neutron
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_password $NEUTRON_PASS
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip controller
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret $METADATA_SECRET

#Configure Modular Layer 2 (ML2) plugin
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers gre
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types gre
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_gre tunnel_id_ranges 1:1000
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs local_ip $NET_TUN
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs tunnel_type gre
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs enable_tunneling True
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True

#restart and run service on boot
service openvswitch restart
chkconfig openvswitch on

#Configure external bridge & create networks
#Add integration bridge
ovs-vsctl add-br br-int
#Add external brdige
ovs-vsctl add-br br-ext
#Add port to the br-ext
#ovs-vsctl add-port br-ex





ln -s plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
cp /etc/init.d/neutron-openvswitch-agent /etc/init.d/neutron-openvswitch-agent.orig
sed -i 's,plugins/openvswitch/ovs_neutron_plugin.ini,plugin.ini,g' /etc/init.d/neutron-openvswitch-agent

service neutron-openvswitch-agent start
service neutron-l3-agent start
service neutron-dhcp-agent start
service neutron-metadata-agent start
service neutron-server start
chkconfig neutron-openvswitch-agent on
chkconfig neutron-l3-agent on
chkconfig neutron-dhcp-agent on
chkconfig neutron-metadata-agent on
chkconfig neutron-server on


