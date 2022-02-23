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
        SERVER=$s envsubst "\$SERVER" < ./rp-noroot.conf.header.template >> env/reverse_proxy/rp.$s.conf.tmp
        for l in `cat env/reverse_proxy/servers.$s.csv.tmp`
        do
            SERVER=`echo $l | cut -d, -f1`
            LOCATION=`echo $l | cut -d, -f2`
            CONTAINER=`echo $l | cut -d, -f3`
            CONTAINER_PORT=`echo $l | cut -d, -f4`
            METHODS=`echo $l | cut -d, -f6`
            AUTH_MSG=`echo $l | cut -d, -f7`

            echo -n > env/reverse_proxy/rp.location.cond.tmp
            if [ -n "$METHODS" ]
            then
                METHODS=${METHODS} \
                       envsubst "\$METHODS" < ./rp-common.conf.location.methods.template >> env/reverse_proxy/rp.location.cond.tmp
            fi
            if [ -n "$AUTH_MSG" ]
            then
                AUTH_MSG=${AUTH_MSG} \
                        envsubst "\$AUTH_MSG" < ./rp-common.conf.location.auth.template >> env/reverse_proxy/rp.location.cond.tmp
            fi
            cat ./rp-noroot.conf.location.template | sed '/-*-CONDITIONS-*-/e cat env/reverse_proxy/rp.location.cond.tmp' | sed '/-*-CONDITIONS-*-/d' >> env/reverse_proxy/rp.$s.conf.location.tmp

            SERVER=${SERVER} \
                  LOCATION=${LOCATION} \
                  CONTAINER=${CONTAINER} \
                  CONTAINER_PORT=${CONTAINER_PORT} \
                  envsubst "\$SERVER \$LOCATION \$CONTAINER \$CONTAINER_PORT" < env/reverse_proxy/rp.$s.conf.location.tmp >> env/reverse_proxy/rp.$s.conf.tmp
        done
        SERVER=$s envsubst "\$SERVER" < ./rp-noroot.conf.trailer.template >> env/reverse_proxy/rp.$s.conf.tmp
    else
        echo -n > env/reverse_proxy/rp.$s.conf.tmp
        for l in `cat env/reverse_proxy/servers.$s.csv.tmp`
        do
            SERVER=`echo $l | cut -d, -f1`
            LOCATION=`echo $l | cut -d, -f2`
            CONTAINER=`echo $l | cut -d, -f3`
            CONTAINER_PORT=`echo $l | cut -d, -f4`
            METHODS=`echo $l | cut -d, -f6`
            AUTH_MSG=`echo $l | cut -d, -f7`

            echo -n > env/reverse_proxy/rp.location.cond.tmp
            if [ -n "$METHODS" ]
            then
                METHODS=${METHODS} \
                       envsubst "\$METHODS" < ./rp-common.conf.location.methods.template >> env/reverse_proxy/rp.location.cond.tmp
            fi
            if [ -n "$AUTH_MSG" ]
            then
                AUTH_MSG=${AUTH_MSG} \
                        envsubst "\$AUTH_MSG" < ./rp-common.conf.location.auth.template >> env/reverse_proxy/rp.location.cond.tmp
            fi
            cat ./rp.conf.template | sed '/-*-CONDITIONS-*-/e cat env/reverse_proxy/rp.location.cond.tmp' | sed '/-*-CONDITIONS-*-/d' >> env/reverse_proxy/rp.$s.tmp
            
            SERVER=${SERVER} \
                  LOCATION=${LOCATION} \
                  CONTAINER=${CONTAINER} \
                  CONTAINER_PORT=${CONTAINER_PORT} \
                  envsubst "\$SERVER \$LOCATION \$CONTAINER \$CONTAINER_PORT" < env/reverse_proxy/rp.$s.tmp >> env/reverse_proxy/rp.$s.conf.tmp
        done
    fi
done

# Concatenate all server definitions
cat env/reverse_proxy/*.conf.tmp > env/reverse_proxy/rp.conf

# Generate docker-compose.yml
echo -n > env/reverse_proxy/docker-compose.yml
cat docker-compose.yml.container.template >> env/reverse_proxy/docker-compose.yml
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
