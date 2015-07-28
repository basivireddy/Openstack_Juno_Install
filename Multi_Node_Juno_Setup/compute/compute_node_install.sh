#!/bin/bash
echo "Make sure to refer READ ME file before executing the script"
if [ $(whoami) != "root" ]
then
    echo "Please switch to root in order to execute this script"
    exit 1
else
echo "you are root user, Script will continue"
fi
read -p  "Enter the compute_node_ip:" compute_node_ip
read -p  "Enter the password to set for admin and for all services:" adminpass
read -p  "Enter the rabbitmq server password :" RABBITMQ_PASS

sleep 5

apt-get install -y  ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" "trusty-updates/juno main" > /etc/apt/sources.list.d/cloudarchive-juno.list
apt-get -y update 
apt-get -y dist-upgrade



sed -i 's/#net.ipv4.conf.all.rp_filter=1/net.ipv4.conf.all.rp_filter=0/g' /etc/sysctl.conf
sed -i 's/#net.ipv4.conf.default.rp_filter=1/net.ipv4.conf.default.rp_filter=0/g' /etc/sysctl.conf

apt-get install -y ntp 
service ntp restart

apt-get install -y  rabbitmq-server 
rabbitmqctl change_password guest $RABBITMQ_PASS
service rabbitmq-server restart

cd config
find . -type f | xargs perl -p -i -e "s/compute_node_ip/$compute_node_ip/g"
find . -type f | xargs perl -p -i -e "s/adminpass/$adminpass/g"
find . -type f | xargs perl -p -i -e "s/RABBITMQ_PASS/$RABBITMQ_PASS/g"
cd ..


echo "Compute service installation is in progress........"
sleep 5
apt-get install -y  nova-compute sysfsutils
cp config/nova/nova.conf /etc/nova/nova.conf
a=`egrep -c '(vmx|svm)' /proc/cpuinfo`
b=0
if [ $a -eq $b ] ; then
        sed -i 's/kvm/qemu/g' /etc/nova/nova-compute.conf
fi
service nova-compute restart
rm -f /var/lib/nova/nova.sqlite


echo "Networking service installation is in progress........"
sleep 5
apt-get install -y neutron-plugin-ml2 neutron-plugin-openvswitch-agent
service openvswitch-switch restart
cp config/neutron/neutron.conf /etc/neutron/neutron.conf
cp config/neutron/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini

service nova-compute restart
service openvswitch-switch restart
service neutron-plugin-openvswitch-agent restart

