#!/bin/bash

# The following bash script will populate Keystone with some initial data:
#    Projects: admin and services
#    Roles: admin, Member
#    Users: admin, demo, nova, glance, neutron, and cinder
#    Services: compute, volume, image, identity, ec2, and network
#
# Modify these variables as needed
# Default value parameter expansion gives follwoing behavior
# ./Bash_keystone_initial.sh will put ADMIN_PASSWORD to value default 'password'
#       and also SERVICE_TENANT_NAME to value default 'service'
# To change those varaibles, call script like
#   ADMIN_PASSWORD='ubuntu' SERVICE_TENANT_NAME=admin ./Bash_keystone_initial.sh
# This will set the variables before the script is called.
ADMIN_PASSWORD=${ADMIN_PASSWORD:-adminpass}
SERVICE_PASSWORD=${SERVICE_PASSWORD:-$ADMIN_PASSWORD}
DEMO_PASSWORD=${DEMO_PASSWORD:-$ADMIN_PASSWORD}
export OS_SERVICE_TOKEN="01ac471be5e93404e3e2"
export OS_SERVICE_ENDPOINT="http://controller:35357/v2.0"
SERVICE_TENANT_NAME=${SERVICE_TENANT_NAME:-service}
#
MYSQL_USER=keystone
MYSQL_DATABASE=keystone
MYSQL_HOST=localhost
MYSQL_PASSWORD=adminpass
#
KEYSTONE_REGION=IPTC
KEYSTONE_HOST_EXT=controller
KEYSTONE_HOST_INT=controller

# Shortcut function to get a newly generated ID
function get_field() {
    while read data; do
        if [ "$1" -lt 0 ]; then
            field="(\$(NF$1))"
        else
            field="\$$(($1 + 1))"
        fi
        echo "$data" | awk -F'[ \t]*\\|[ \t]*' "{print $field}"
    done
}

# Tenants
ADMIN_TENANT=$(keystone tenant-create --name=admin | grep " id " | get_field 2)
DEMO_TENANT=$(keystone tenant-create --name=demo | grep " id " | get_field 2)
SERVICE_TENANT=$(keystone tenant-create --name=$SERVICE_TENANT_NAME | grep " id " | get_field 2)

# Users
ADMIN_USER=$(keystone user-create --name=admin --pass="$ADMIN_PASSWORD" --email=admin@ostack.iptc.alcatel-lucent.com | grep " id " | get_field 2)
DEMO_USER=$(keystone user-create --name=demo --pass="$DEMO_PASSWORD" --email=demo@ostack.iptc.alcatel-lucent.com --tenant-id=$DEMO_TENANT | grep " id " | get_field 2)
NOVA_USER=$(keystone user-create --name=nova --pass="$SERVICE_PASSWORD" --tenant-id $SERVICE_TENANT --email=nova@ostack.iptc.alcatel-lucent.com | grep " id " | get_field 2)
GLANCE_USER=$(keystone user-create --name=glance --pass="$SERVICE_PASSWORD" --tenant-id $SERVICE_TENANT --email=glance@ostack.iptc.alcatel-lucent.com | grep " id " | get_field 2)
NEUTRON_USER=$(keystone user-create --name=neutron --pass="$SERVICE_PASSWORD" --tenant-id $SERVICE_TENANT --email=neutron@ostack.iptc.alcatel-lucent.com | grep " id " | get_field 2)
CINDER_USER=$(keystone user-create --name=cinder --pass="$SERVICE_PASSWORD" --tenant-id $SERVICE_TENANT --email=cinder@ostack.iptc.alcatel-lucent.com | grep " id " | get_field 2)
HEAT_USER=$(keystone user-create --name=heat --pass="$SERVICE_PASSWORD" --tenant-id $SERVICE_TENANT --email=heat@ostack.iptc.alcatel-lucent.com | grep " id " | get_field 2)
# Roles
ADMIN_ROLE=$(keystone role-create --name=admin | grep " id " | get_field 2)
MEMBER_ROLE=$(keystone role-create --name=Member | grep " id " | get_field 2)

# Add Roles to Users in Tenants
keystone user-role-add --user-id $ADMIN_USER --role-id $ADMIN_ROLE --tenant-id $ADMIN_TENANT
keystone user-role-add --tenant-id $SERVICE_TENANT --user-id $NOVA_USER --role-id $ADMIN_ROLE
keystone user-role-add --tenant-id $SERVICE_TENANT --user-id $GLANCE_USER --role-id $ADMIN_ROLE
keystone user-role-add --tenant-id $ADMIN_TENANT --user-id $GLANCE_USER --role-id $ADMIN_ROLE
keystone user-role-add --tenant-id $SERVICE_TENANT --user-id $NEUTRON_USER --role-id $ADMIN_ROLE
keystone user-role-add --tenant-id $SERVICE_TENANT --user-id $CINDER_USER --role-id $ADMIN_ROLE
keystone user-role-add --tenant-id $SERVICE_TENANT --user-id $HEAT_USER --role-id $ADMIN_ROLE
keystone user-role-add --tenant-id $DEMO_TENANT --user-id $DEMO_USER --role-id $MEMBER_ROLE


# Create services
COMPUTE_SERVICE=$(keystone service-create --name nova --type compute --description 'OpenStack Compute Service' | grep " id " | get_field 2)
VOLUME_SERVICE=$(keystone service-create --name cinder --type volume --description 'OpenStack Volume Service' | grep " id " | get_field 2)
IMAGE_SERVICE=$(keystone service-create --name glance --type image --description 'OpenStack Image Service' | grep " id " | get_field 2)
IDENTITY_SERVICE=$(keystone service-create --name keystone --type identity --description 'OpenStack Identity' | grep " id " | get_field 2)
EC2_SERVICE=$(keystone service-create --name ec2 --type ec2 --description 'OpenStack EC2 service' | grep " id " | get_field 2)
NETWORK_SERVICE=$(keystone service-create --name neutron --type network --description 'OpenStack Networking service' | grep " id " | get_field 2)
HEAT_SERVICE=$(keystone service-create --name heat --type orchestration --description 'Heat Orchestration API' | grep " id " | get_field 2)


# Create endpoints
keystone endpoint-create --region $KEYSTONE_REGION --service-id $COMPUTE_SERVICE --publicurl 'http://'"$KEYSTONE_HOST_EXT"':8774/v2/$(tenant_id)s' --adminurl 'http://'"$KEYSTONE_HOST_INT"':8774/v2/$(tenant_id)s' --internalurl 'http://'"$KEYSTONE_HOST_INT"':8774/v2/$(tenant_id)s'
keystone endpoint-create --region $KEYSTONE_REGION --service-id $VOLUME_SERVICE --publicurl 'http://'"$KEYSTONE_HOST_EXT"':8776/v1/$(tenant_id)s' --adminurl 'http://'"$KEYSTONE_HOST_INT"':8776/v1/$(tenant_id)s' --internalurl 'http://'"$KEYSTONE_HOST_INT"':8776/v1/$(tenant_id)s'
keystone endpoint-create --region $KEYSTONE_REGION --service-id $IMAGE_SERVICE --publicurl 'http://'"$KEYSTONE_HOST_EXT"':9292' --adminurl 'http://'"$KEYSTONE_HOST_INT"':9292' --internalurl 'http://'"$KEYSTONE_HOST_INT"':9292'
keystone endpoint-create --region $KEYSTONE_REGION --service-id $IDENTITY_SERVICE --publicurl 'http://'"$KEYSTONE_HOST_EXT"':5000/v2.0' --adminurl 'http://'"$KEYSTONE_HOST_INT"':35357/v2.0' --internalurl 'http://'"$KEYSTONE_HOST_INT"':5000/v2.0'
keystone endpoint-create --region $KEYSTONE_REGION --service-id $EC2_SERVICE --publicurl 'http://'"$KEYSTONE_HOST_EXT"':8773/services/Cloud' --adminurl 'http://'"$KEYSTONE_HOST_INT"':8773/services/Admin' --internalurl 'http://'"$KEYSTONE_HOST_INT"':8773/services/Cloud'
keystone endpoint-create --region $KEYSTONE_REGION --service-id $NETWORK_SERVICE --publicurl 'http://'"$KEYSTONE_HOST_EXT"':9696/' --adminurl 'http://'"$KEYSTONE_HOST_INT"':9696/' --internalurl 'http://'"$KEYSTONE_HOST_INT"':9696/'
keystone endpoint-create --region $KEYSTONE_REGION --service-id $HEAT_SERVICE --publicurl 'http://'"$KEYSTONE_HOST_EXT"':8004/v1/$(tenant_id)s' --adminurl 'http://'"$KEYSTONE_HOST_INT"':8004/v1/$(tenant_id)s' --internalurl 'http://'"$KEYSTONE_HOST_INT"':8004/v1/$(tenant_id)s '
