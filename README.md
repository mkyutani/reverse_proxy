# Reverse Proxy by nginx and docker networks

## Introduction

Building reverse proxy by nginx communicating internal docker networks.

## Installation

1. `git clone` this repository.

```
~$ git clone <repository>
~$ cd reverse_proxy
```

2. Initialize local setup environment, with generating server definition file in env/ and creating working directory env/reverse_proxy.

```
~/reverse_proxy$ ./init.sh
```

3. Edit server definition file.

```
~/reverse_proxy$ vi env/servers.csv
```

4. Edit .htpasswd for authentication, if necessary.

```
~/reverse_proxy$ sudo htpasswd -b _htpasswd <auth_user> <auth_password>
```

4. Generate docker-compose.yml and conf files for nginx.

    1. If SSL is not necessary, run setup.sh.
    ```
    ~/reverse_proxy$ ./setup.sh
    ```

    2. If you need SSL, (1)copy _env to .env, (2)set your.domain in .env file, and (3)run setup.ssl.sh instead of setup.sh.  In this case, you will need to set up letsencrypt in /etc/letsencrypt/your.domain/ on the host in advance.
 
    ```
    ~/reverse_proxy$ ./setup.ssl.sh
    ```

- You will find some files after executing setup.sh or setup.ssl.sh.

    - env/reverse_proxy/default.conf ... /etc/nginx/default.conf in reverse proxy server container.
    - env/reverse_proxy/docker-compose.yml ... docker-compose.yml
    - env/reverse_proxy/nginx.conf ... /etc/nginx/nginx.conf in reverse proxy server container.
    - env/reverse_proxy/rp.conf ... Server definition. /etc/nginx/conf.d/rp.conf in reverse proxy server container.

5. Run docker-compose.

```
~/reverse_proxy$ cd env/reverse_proxy
~/reverse_proxy/env/reverse_proxy$ docker-compose up -d
~/reverse_proxy/env/reverse_proxy$ docker-compose ps # Confirm status
~/reverse_proxy/env/reverse_proxy$ docker-compose logs # Confirm logs
```
6. Test (samples)

```
~/reverse_proxy/env/reverse_proxy$ curl http://hoge.mydomain.com/
~/reverse_proxy/env/reverse_proxy$ curl http://hage.mydomain.com/
~/reverse_proxy/env/reverse_proxy$ curl http://root.mydomain.com/hoge/
```

# Sample input

## env/reverse_proxy/servers.csv (input)

```
#SERVER,LOCATION,CONTAINER,CONTAINER_PORT,CONTAINER_NETWORK,METHODS,AUTH_MSG
hoge.mydomain.com,/,docker-container1,80,docker-network1
hage.mydomain.com,/,docker-container2,8080,docker-network2,GET|PUT
hage-restrict.mydomain.com,/,docker-container2,8080,docker-network2,,Authentication
root.mydomain.com,/hoge/,docker-container1,80,docker-network1
```

# License

MIT License.
