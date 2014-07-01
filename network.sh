#!/bin/bash -x
#
#Service Password: 548295a7ebf749b74d42
#
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
#		chkconfig qpidd on;
#
#	Kernel functions:
#		/etc/sysctl.conf
#			net.ipv4.ip_forward=1
#			net.ipv4.conf.all.rp_filter=0
#			net.ipv4.conf.default.rp_filter=0
# 		sysctl -p
#	Hosts:
#		add 'controller' to host with the management IP
### Neutron Setup ###
echo "Installing Networking Service (Neutron)...";
yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch -y;
echo "Done.";

echo "Configuring Neutron...";
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone;
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://controller:5000;
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_host controller;
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_protocol http;
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_port 35357;
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_tenant_name service;
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_user neutron;
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_password 548295a7ebf749b74d42;
openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend neutron.openstack.common.rpc.impl_qpid;
openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_hostname controller;
openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2;
openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins router;
# Disable service_providers
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver;
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT use_namespaces True;
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver;
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq;
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT use_namespaces True;
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT auth_url http://controller:5000/v2.0;
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT auth_region regionOne;
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_tenant_name service;
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_user neutron;
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_password 548295a7ebf749b74d42;
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip controller;
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret 548295a7ebf749b74d42;
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers gre;
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types gre;
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch;
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_gre tunnel_id_ranges 1:1000;
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs local_ip 10.0.1.21;
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs tunnel_type gre;
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs enable_tunneling True;
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver;
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True;
echo "Done.";

#Configure external bridge & create networks later
