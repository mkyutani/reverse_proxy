# Reverse Proxy by nginx and docker networks

## Introduction

The purpose of this repository is building reverse proxy communicating internal docker networks.

## Installation

1. `git clone` this directory.

```
~$ git clone <repository>
~$ cd reverse_proxy
```

2. Initialize local setup environment, with generating server definition file in env/.

```
~/reverse_proxy$ ./init.sh
~/reverse_proxy$ cat env/servers.csv
#SERVER,LOCATION,CONTAINER,CONTAINER_PORT,CONTAINER_NETWORK
```
3. Edit server definition file.

```
~/reverse_proxy$ vi env/servers.csv
```

4. Setup docker-compose.yml and conf files for nginx.

```
~/reverse_proxy$ ./setup.sh
```

- You will find some files after setup 4.

    - env/default.conf ... 0 byte file prepared to overwrite the original file.
    - env/docker-compose.yml ... docker-compose.yml
    - env/nginx.conf ... /etc/nginx/nginx.conf in reverse proxy server container.
    - env/rp.conf ... Server definition. /etc/nginx/conf.d/rp.conf in reverse proxy server container.

5. Run docker-compose.

```
~/reverse_proxy$ cd env
~/reverse_proxy/env$ docker-compose up -d
~/reverse_proxy/env$ docker-compose ps # Confirm status
~/reverse_proxy/env$ docker-compose logs # Confirm logs
```
6. Test (samples)

```
~/reverse_proxy/env$ curl http://hoge.mydomain.com/
~/reverse_proxy/env$ curl http://hage.mydomain.com/
~/reverse_proxy/env$ curl http://root.mydomain.com/hoge/
```

# Sample input/output

## env/servers.csv (input)

```
#SERVER,LOCATION,CONTAINER,CONTAINER_PORT,CONTAINER_NETWORK
hoge.mydomain.com,/,docker-container1,80,docker-network1
hage.mydomain.com,/,docker-container2,8080,docker-network2
root.mydomain.com,/hoge/,docker-container1,80,docker-network1
```

## env/rp.conf (generated by setup.sh)

```
server {
    listen 80;
    server_name hage.mydomain.com;

    location / {
        proxy_set_header  Host                $host;
        proxy_set_header  X-Real-IP           $remote_addr;
        proxy_set_header  X-Forwarded-Host    $host;
        proxy_set_header  X-Forwarded-Server  $host;
        proxy_set_header  X-Forwarded-For     $proxy_add_x_forwarded_for;
        proxy_pass        http://docker-container2:8080/;
        proxy_redirect    default;
    }
}

server {
    listen 80;
    server_name hoge.mydomain.com;

    location / {
        proxy_set_header  Host                $host;
        proxy_set_header  X-Real-IP           $remote_addr;
        proxy_set_header  X-Forwarded-Host    $host;
        proxy_set_header  X-Forwarded-Server  $host;
        proxy_set_header  X-Forwarded-For     $proxy_add_x_forwarded_for;
        proxy_pass        http://docker-container1:80/;
        proxy_redirect    default;
    }
}

server {

    listen 80;
    server_name root.mydomain.com;

    location /hoge/ {
        proxy_set_header  Host                $host;
        proxy_set_header  X-Real-IP           $remote_addr;
        proxy_set_header  X-Forwarded-Host    $host;
        proxy_set_header  X-Forwarded-Server  $host;
        proxy_set_header  X-Forwarded-For     $proxy_add_x_forwarded_for;
        proxy_pass        http://docker-container1:80/;
        proxy_redirect    default;
    }


    location / {
        return 444; 
    }

    error_page  400 403 404       /40x.html;
    location = /40x.html {
        root   /usr/share/nginx/html;
    }

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

}

```

## env/docker-compose.conf (generated by setup.sh)

```
version: '3'

services:
  reverse-proxy:
    image: nginx
    container_name: reverse-proxy
    command: sh -c "cp -f /etc/nginx/tmp/nginx.conf /etc/nginx && cp -f /etc/nginx/tmp/conf.d/*.conf /etc/nginx/conf.d && echo -n > /usr/share/nginx/html/index.html && echo -n > /usr/share/nginx/html/40x.html && echo -n > /usr/share/nginx/html/50x.html && nginx -g 'daemon off;'"
    volumes:
      - ./nginx.conf:/etc/nginx/tmp/nginx.conf
      - ./default.conf:/etc/nginx/tmp/conf.d/default.conf
      - ./rp.conf:/etc/nginx/tmp/conf.d/rp.conf
    ports:
      - 80:80
    networks:
      - docker-network1
      - docker-network2
networks:
  docker-network1:
    external: true
  docker-network2:
    external: true
```

# Detail of files generated by setup.sh

- env/nginx.conf
  - Copy of nginx.conf.template
- env/default.conf
  - Copy of default.conf.template
- env/rp.conf
  - (a) If the location root (/) is defined:
    - Replacing server, location and container information of rp.conf.template
  - (b) Otherwise:
    - Construct data from rp-noroot.conf.header.template, location data, and rp-noroot.conf.trailer.template
    - Location data is replaced server, location and container information of rp-noroot.conf.location.template
  - Finally concatenate files created by (a) and (b) processes
- env/docker-compose.yml
  - Concatenate some fragment files:
    - Container definition: docker-compose.yml.container.template
    - Docker service networks linked by the container: docker-compose.yml.services-networks.subsection.template
    - Docker external networks: docker-compose.yml.networks.section.template

# License

MIT License.
