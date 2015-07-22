Welcome to OpenStack Juno installation manual !

This document is based on the  OpenStack Official Documentation ` http://docs.openstack.org/juno/install-guide/install/apt/content/index.html` for Juno. 




* Edit /etc/hosts::

   
```  
       vi /etc/hosts
       #controller
       10.0.0.11       controller   
       
```

   
Install Compute node
-------------------------  
* Change to super user mode::

    ` sudo su `

*  Assign permission to exicute script

```
    cd openstack_juno_install/Multi_Node_Juno_Setup/compute
    chmod 777 *
```

* start script   ` ./compute_node_install.sh `

