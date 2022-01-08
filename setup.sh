#!/usr/bin/env bash

# Generate nginx.conf
cp -f nginx.conf env

# Generate default.con
cp -f default.conf env

# Generate rp.conf
echo -n > env/rp.conf
for s in `grep -v ^# env/servers.csv`
do
	eval `echo $s | sed -r 's/^([^,]+),([^,]+),([^,]+),([^,]+)(.*)/SERVER=\1 LOCATION=\2 CONTAINER=\3 CONTAINER_PORT=\4 envsubst \\\\\\\"\\\\\\\$SERVER \\\\\\\$LOCATION \\\\\\\$CONTAINER \\\\\\\$CONTAINER_PORT\\\\\\\" < \.\/rp\.conf\.template >>env\/rp\.conf/'`
done

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
