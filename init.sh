#!/usr/bin/env sh

mkdir -p env/reverse_proxy
cp _servers.csv.template env/servers.csv
cp _htpasswd.template env/_htpasswd
