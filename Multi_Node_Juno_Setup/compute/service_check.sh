#!/bin/bash
echo "service check"
if [ $(whoami) != "root" ]
then
    echo "Please switch to root in order to execute this script"
    exit 1
fi
source keystonerc

echo -e "service's  \n 1.keystone \n 2.glance \n 3.nova \n 4.neutron \n horizon \n"

echo "Enter which service you have to check"
read  choice



case  $choice in 
	1) 
	keystone tenant-list
	if [ $? == 0 ]
    then
        echo "keystone service running "
    else
        echo "keystone not service running "
    fi
	;;
	2) 
	glance image-list
	if [ $? == 0 ]
    then
        echo "glance service running "
    else
        echo "glance not service running "
    fi
	;;
	3) 
	nova service-list
	if [ $? == 0 ]
    then
        echo "nova service running "
    else
        echo "nova not service running "
    fi
	;;
	4) 
	neutron agent-list
	if [ $? == 0 ]
    then
        echo "neutron service running "
    else
        echo "neutron not service running "
    fi
	;;
	*) echo "INVALID NUMBER!" ;;
esac
