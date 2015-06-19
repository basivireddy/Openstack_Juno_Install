####
The shell script's to install Openstack Juno on Multi node or Single Node Setup.
####

Welcome to OpenStack Juno installation manual !

This document is based on `the OpenStack Official Documentation <http://docs.openstack.org/juno/install-guide/install/apt/content/index.html>`_ for Juno. 

===============================

**Contributors:**

Basivireddy: d.basivireddy@gmail.com

==========================================

### 1. Download Juno Installation Script's.

Clone the git repo: 
```shell
git clone https://github.com/basivireddy/Openstack_Juno_Install.git
```

.. contents::
   

Multi Node Juno Installtion
==========================================

In this installation guide, we cover the step-by-step process of installing Openstack Juno on Ubuntu 14.04.  We consider a multi-node architecture with Openstack Networking (Neutron) that requires three node types: 

+ **Controller Node** that runs management services (keystone, Horizon…) needed for OpenStack to function.

+ **Compute Node** that runs the virtual machine instances in OpenStack. 

We have deployed a single compute node but you can simply add more compute nodes to our multi-node installation, if needed.

So, let’s prepare the nodes for OpenStack installation!

Configure Controller node
-------------------------

The controller node has two Network Interfaces: eth0 (used for management network) and eth1 is external.

* Change to super user mode::

    sudo su

* Set the hostname::

    vi /etc/hostname
    controller


* Edit /etc/hosts::

    vi /etc/hosts
        
    #controller
    10.0.0.11       controller
        
    # compute1  
    10.0.0.31       compute1
    
* Note::

    Remove or comment the line beginning with 127.0.1.1.

* Edit network settings to configure the interfaces eth0 and eth1::

    vi /etc/network/interfaces
      
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

* Restart network and if needed **reboot** the system to activate the changes::

    ifdown eth0 && ifup eth0
    
    ifdown eth1 && ifup eth1
    
Configure Compute node
----------------------

The network node has two network Interfaces: eth0 for management use and 
eth1 for connectivity between VMs.


* Change to super user mode::

    sudo su

* Set the hostname::

    vi /etc/hostname
    compute1


* Edit /etc/hosts::

    vi /etc/hosts
    
    # compute1
    10.0.0.31       compute1
  
    #controller
    10.0.0.11       controller

    
* Note::

    Remove or comment the line beginning with 127.0.1.1.

* Edit network settings to configure the interfaces eth0 and eth1::

    vi /etc/network/interfaces
  
    # The management network interface    
    auto eth0
    iface eth0 inet static
        address 10.0.0.31
        netmask 255.255.255.0
        network 10.0.0.0
  
    # VM traffic interface     
    auto eth1
    iface eth1 inet static
        address 10.0.1.31
        netmask 255.255.255.0
        network 10.0.1.0

* In order to be able to reach public network for installing openstack packages, we recommend to add a new interface (e.g. eth2) connected to the public network or configure nat Service on the management network.


* Restart network and if needed **reboot** the system to activate the changes::
  
    ifdown eth0 && ifup eth0
      
    ifdown eth1 && ifup eth1


Verify connectivity
-------------------

We recommend that you verify network connectivity to the internet and among the nodes before proceeding further.

    
* From the controller node::

    # ping a site on the internet:
    ping openstack.org

  
    # ping the management interface on the compute node:
    ping compute1

* From the network node::

    # ping a site on the internet:
    ping openstack.org

    # ping the management interface on the controller node:
    ping controller

    # ping the VM traffic interface on the compute node:
    ping 10.0.1.31
    
* From the compute node::

    # ping a site on the internet:
    ping openstack.org

    # ping the management interface on the controller node:
    ping controller

Install 
=======

Now everything is ok :) So let's go ahead and install it !


Controller Node
---------------

Let's start with the controller ! the cornerstone !

