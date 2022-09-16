# Tunneling traffic via TcpProxy

## Usage

### Generate SSL certificates
```sh
curl https://raw.githubusercontent.com/jewertow/openssl-cert-gen/master/tls.sh | SUBJECT="tunnel-proxy" sh
curl https://raw.githubusercontent.com/jewertow/openssl-cert-gen/master/tls.sh | SUBJECT="www.wikipedia.org" sh
```

### Run containers
```sh
./setup-log-files.sh
docker-compose up
```

### Test connectivity
```sh
export PROXY_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' gateway)
docker exec -it client /bin/sh -c \
    "curl -v --insecure --resolve www.wikipedia.org:443:$PROXY_IP https://www.wikipedia.org/ | grep -o \"<title>.*</title>\""
```
