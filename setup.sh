#!/usr/bin/env bash

# Generate overwritten configuration files
cp -f nginx.conf.template env/nginx.conf
cp -f default.conf.template env/default.conf

# Separate servers.csv into each server's
SERVERS=`grep -v ^# env/servers.csv | cut -d, -f1 | sort | uniq`

# Generate server definition
for s in $SERVERS
do
    sed "/^$s/!d" env/servers.csv > env/servers.$s.csv.tmp
    if [ `egrep -c -v '^[^,]+,/,' env/servers.$s.csv.tmp` -ne 0 ]
    then
        echo -n > env/rp.$s.conf.tmp
        SERVER=$s envsubst "\$SERVER" < ./rp-noroot.conf.header.template >> env/rp.$s.conf.tmp
        for l in `cat env/servers.$s.csv.tmp`
        do
	    eval `echo $l | sed -r 's/^([^,]+),([^,]+),([^,]+),([^,]+)(.*)/SERVER=\1 LOCATION=\2 CONTAINER=\3 CONTAINER_PORT=\4 envsubst \\\\\\\"\\\\\\\$SERVER \\\\\\\$LOCATION \\\\\\\$CONTAINER \\\\\\\$CONTAINER_PORT\\\\\\\" < \.\/rp-noroot\.conf\.location\.template >> env\/rp\.\1.conf.tmp/'`
        done
        SERVER=$s envsubst "\$SERVER" < ./rp-noroot.conf.trailer.template >> env/rp.$s.conf.tmp
    else
        echo -n > env/rp.$s.conf.tmp
        for l in `cat env/servers.$s.csv.tmp`
        do
            eval `echo $l | sed -r 's/^([^,]+),([^,]+),([^,]+),([^,]+)(.*)/SERVER=\1 LOCATION=\2 CONTAINER=\3 CONTAINER_PORT=\4 envsubst \\\\\\\"\\\\\\\$SERVER \\\\\\\$LOCATION \\\\\\\$CONTAINER \\\\\\\$CONTAINER_PORT\\\\\\\" < \.\/rp\.conf\.template >> env\/rp\.\1.conf.tmp/'`
        done
    fi
done

# Concatenate all server definitions
cat env/*.conf.tmp > env/rp.conf

# Generate docker-compose.yml
echo -n > env/docker-compose.yml
cat docker-compose.yml.container.template >> env/docker-compose.yml
cat docker-compose.yml.services-networks.subsection.template >> env/docker-compose.yml
for s in `grep -v ^# env/servers.csv | cut -d, -f5 | sort | uniq`
do
	CONTAINER_NETWORK=$s envsubst "\$CONTAINER_NETWORK" < ./docker-compose.yml.services-networks.placeholder.template >> env/docker-compose.yml
done
cat docker-compose.yml.networks.section.template >> env/docker-compose.yml
for s in `grep -v ^# env/servers.csv | cut -d, -f5 | sort | uniq`
do
        CONTAINER_NETWORK=$s envsubst "\$CONTAINER_NETWORK" < ./docker-compose.yml.networks.placeholder.template >> env/docker-compose.yml
done

# Clean up temporary files
rm env/*.tmp
