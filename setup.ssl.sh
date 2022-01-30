#!/usr/bin/env bash

# Generate overwritten configuration files
cp -f nginx.conf.template env/reverse_proxy/nginx.conf
cp -f default.conf.template env/reverse_proxy/default.conf

# Separate servers.csv into each server's
SERVERS=`grep -v ^# env/servers.csv | cut -d, -f1 | sort | uniq`

# Generate server definition
for s in $SERVERS
do
    sed "/^$s/!d" env/servers.csv > env/reverse_proxy/servers.$s.csv.tmp
    if [ `egrep -c -v '^[^,]+,/,' env/reverse_proxy/servers.$s.csv.tmp` -ne 0 ]
    then
        echo -n > env/reverse_proxy/rp.$s.conf.tmp
        SERVER=$s envsubst "\$SERVER" < ./rp-noroot.conf.header.ssl.template >> env/reverse_proxy/rp.$s.conf.tmp
        for l in `cat env/reverse_proxy/servers.$s.csv.tmp`
        do
	    eval `echo $l | sed -r 's/^([^,]+),([^,]+),([^,]+),([^,]+)(.*)/SERVER=\1 LOCATION=\2 CONTAINER=\3 CONTAINER_PORT=\4 envsubst \\\\\\\"\\\\\\\$SERVER \\\\\\\$LOCATION \\\\\\\$CONTAINER \\\\\\\$CONTAINER_PORT\\\\\\\" < \.\/rp-noroot\.conf\.location\.template >> env\/reverse_proxy\/rp\.\1.conf.tmp/'`
        done
        SERVER=$s envsubst "\$SERVER" < ./rp-noroot.conf.trailer.template >> env/reverse_proxy/rp.$s.conf.tmp
    else
        echo -n > env/reverse_proxy/rp.$s.conf.tmp
        for l in `cat env/reverse_proxy/servers.$s.csv.tmp`
        do
            eval `echo $l | sed -r 's/^([^,]+),([^,]+),([^,]+),([^,]+)(.*)/SERVER=\1 LOCATION=\2 CONTAINER=\3 CONTAINER_PORT=\4 envsubst \\\\\\\"\\\\\\\$SERVER \\\\\\\$LOCATION \\\\\\\$CONTAINER \\\\\\\$CONTAINER_PORT\\\\\\\" < \.\/rp\.conf\.ssl\.template >> env\/reverse_proxy\/rp\.\1.conf.tmp/'`
        done
    fi
done

# Concatenate all server definitions
cat env/reverse_proxy/*.conf.tmp > env/reverse_proxy/rp.conf

# Generate docker-compose.yml
echo -n > env/reverse_proxy/docker-compose.yml
cat docker-compose.yml.container.ssl.template >> env/reverse_proxy/docker-compose.yml
cat docker-compose.yml.services-networks.subsection.template >> env/reverse_proxy/docker-compose.yml
for s in `grep -v ^# env/servers.csv | cut -d, -f5 | sort | uniq`
do
	CONTAINER_NETWORK=$s envsubst "\$CONTAINER_NETWORK" < ./docker-compose.yml.services-networks.placeholder.template >> env/reverse_proxy/docker-compose.yml
done
cat docker-compose.yml.networks.section.template >> env/reverse_proxy/docker-compose.yml
for s in `grep -v ^# env/servers.csv | cut -d, -f5 | sort | uniq`
do
        CONTAINER_NETWORK=$s envsubst "\$CONTAINER_NETWORK" < ./docker-compose.yml.networks.placeholder.template >> env/reverse_proxy/docker-compose.yml
done

# Clean up temporary files
rm env/reverse_proxy/*.tmp
