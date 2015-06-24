Single Node Juno Installtion
==========================================

In this installation guide, we cover the step-by-step process of installing Openstack Juno on Ubuntu 14.04.  We consider a multi-node architecture with Openstack Networking (Neutron) that requires three node types: 

+ **Controller Node** that runs all services needed for OpenStack to function.

Configure Controller node
-------------------------

The controller node has two Network Interfaces: eth0 (used for management network) and eth1 is external.

* Change to super user mode::

    ``` sudo su  
    ```

* Set the hostname::

   ``` vi /etc/hostname
       controller
    
   ```


* Edit /etc/hosts::

   ``` vi /etc/hosts
        
    #controller
    10.0.0.11       controller
        
   ```
    
* Note:: Remove or comment the line beginning with 127.0.1.1.

* Edit network settings to configure the interfaces eth0 and eth1::

   ``` vi /etc/network/interfaces
      
    # The management network interface
    auto eth0
    iface eth0 inet static
        address 10.0.0.11
        netmask 255.255.255.0
        network 10.0.0.0

    # The public network interface
    auto eth1
    iface eth1 inet static
        address 192.168.100.11
        netmask 255.255.255.0
        network 192.168.100.0
        gateway 192.168.100.1
        dns-nameservers 8.8.8.8 8.8.4.4 
     
     ```

* Restart network and if needed **reboot** the system to activate the changes::

   ```
    ifdown eth0 && ifup eth0
    
    ifdown eth1 && ifup eth1 
    
    ```
    