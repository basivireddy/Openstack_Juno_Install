#!/bin/bash
echo "Make sure to refer READ ME file before executing the script"
if [ $(whoami) != "root" ]
then
    echo "Please switch to root in order to execute this script"
    exit 1
else
echo "you are root user, Script will continue"
fi
echo "#################################
OpenStack Juno  installation:
#################################"
sleep 5
read -p  "Enter the password to set for admin and for all services:" adminpass

apt-get install -y  ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" "trusty-updates/juno main" > /etc/apt/sources.list.d/cloudarchive-juno.list
apt-get -y update 
apt-get -y dist-upgrade

hostname=`cat /etc/hosts | grep $controller | awk '{print $2}'`


sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sed -i 's/#net.ipv4.conf.all.rp_filter=1/net.ipv4.conf.all.rp_filter=1/g' /etc/sysctl.conf
sed -i 's/#net.ipv4.conf.default.rp_filter=1/net.ipv4.conf.default.rp_filter=1/g' /etc/sysctl.conf

apt-get install -y ntp 
service ntp restart

cd config
find . -type f | xargs perl -p -i -e "s/adminpass/$adminpass/g"
cd ..

chmod 777 *
chmod 777 config/keystone/*


echo "Mysql server installation is in progress....."
sleep 5
apt-get install -y mariadb-server python-mysqldb
cp config/mysql/my.cnf /etc/mysql/my.cnf
service mysql restart
echo "Creating databases for OpenStack services is in progress......"
sleep 5


mysql -uroot -p$adminpass <<EOF
CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$adminpass';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'$controller' IDENTIFIED BY '$adminpass';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'$hostname' IDENTIFIED BY '$adminpass';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$adminpass';
CREATE DATABASE cinder;
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '$adminpass';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'$controller' IDENTIFIED BY '$adminpass';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'$hostname' IDENTIFIED BY '$adminpass';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '$adminpass';
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$adminpass';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'$controller' IDENTIFIED BY '$adminpass';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'$hostname' IDENTIFIED BY '$adminpass';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$adminpass';
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$adminpass';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'$controller' IDENTIFIED BY '$adminpass';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'$hostname' IDENTIFIED BY '$adminpass';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$adminpass';
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$adminpass';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'$controller' IDENTIFIED BY '$adminpass';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'$hostname' IDENTIFIED BY '$adminpass';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$adminpass';
CREATE DATABASE heat;
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' IDENTIFIED BY '$adminpass';
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'$controller' IDENTIFIED BY '$adminpass';
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'$hostname' IDENTIFIED BY '$adminpass';
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'localhost' IDENTIFIED BY '$adminpass';
FLUSH PRIVILEGES;
EOF

apt-get install -y  rabbitmq-server 
rabbitmqctl change_password guest ubuntu
service rabbitmq-server restart



echo "Identity service installation is in progress......."
sleep 5
apt-get install -y keystone python-keystoneclient
rm /var/lib/keystone/keystone.db
cp config/keystone/keystone.conf /etc/keystone/keystone.conf
service keystone restart
su -s /bin/sh -c "keystone-manage db_sync" keystone
service keystone restart
./config/keystone/keystone_initial.sh
source  keystonerc
keystone tenant-list
keystone user-list
keystone service-list
cd config
service_id=`keystone tenant-list | grep service | awk '{print $2}'`
cd ..
service keystone restart

echo "Image service installation is in progress........"
apt-get install -y glance python-glanceclient
sleep 5
cp config/glance/glance-api.conf /etc/glance/glance-api.conf
cp config/glance/glance-registry.conf /etc/glance/glance-registry.conf
su -s /bin/sh -c "glance-manage db_sync" glance
service glance-registry restart
service glance-api restart
rm -f /var/lib/glance/glance.sqlite




echo "Compute service installation is in progress........"
apt-get install -y  nova-api nova-cert nova-conductor nova-consoleauth nova-novncproxy nova-scheduler python-novaclient
apt-get install -y  nova-compute sysfsutils
cp config/nova/nova.conf /etc/nova/nova.conf
su -s /bin/sh -c "nova-manage db sync" nova
rm -f /var/lib/nova/nova.sqlite
a=`egrep -c '(vmx|svm)' /proc/cpuinfo`
b=0
if [ $a -eq $b ] ; then
        sed -i 's/kvm/qemu/g' /etc/nova/nova-compute.conf
fi
service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
service nova-compute restart


echo "Networking service installation is in progress........"
sleep 5
apt-get install -y neutron-server neutron-plugin-ml2 python-neutronclient
apt-get install -y neutron-plugin-ml2 neutron-plugin-openvswitch-agent neutron-l3-agent neutron-dhcp-agent
cp config/neutron/neutron.conf /etc/neutron/neutron.conf
cp config/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini
cp config/neutron/l3_agent.ini /etc/neutron/l3_agent.ini
cp config/neutron/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade juno" neutron
source keystonerc
service nova-api restart
service nova-scheduler restart
service nova-conductor restart
service neutron-server restart
service openvswitch-switch restart
service neutron-plugin-openvswitch-agent restart
service neutron-l3-agent restart
service neutron-dhcp-agent restart

service openvswitch-switch restart
ovs-vsctl add-br br-ex
service neutron-plugin-openvswitch-agent restart
service neutron-l3-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart



echo "Block storage installation is in progress.........."
apt-get install -y cinder-api cinder-scheduler python-cinderclient
apt-get install -y cinder-volume python-mysqldb
sleep 5
cp config/cinder/cinder.conf /etc/cinder/cinder.conf
su -s /bin/sh -c "cinder-manage db sync" cinder
rm -f /var/lib/cinder/cinder.sqlite
apt-get install -y lvm2
service cinder-scheduler restart
service cinder-api restart
service tgt restart
service cinder-volume restart
apt-get install -y lvm2


echo "Dashboard installation is in progress......"
sleep 5
apt-get install -y openstack-dashboard apache2 libapache2-mod-wsgi memcached python-memcache
apt-get remove --purge  -y openstack-dashboard-ubuntu-theme
service apache2 restart
service memcached restart


echo "End of Open Stack Installation........"
echo "####################################################################
Dashboard is serving at:- $ext_ip/horizon
Admin credentials are:- admin/$adminpass
####################################################################"

echo "For any troubleshooting issues check '/var/log/' folder."
echo "System is going to reboot now........."
sleep 10
reboot
