# Tunneling traffic via TcpProxy

## Usage

### Generate SSL certificates
```sh
curl https://raw.githubusercontent.com/jewertow/openssl-cert-gen/master/tls.sh | sh -s - --subject="tunnel-proxy"
curl https://raw.githubusercontent.com/jewertow/openssl-cert-gen/master/tls.sh | sh -s - --subject="www.wikipedia.org"
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

## TODO
- Change gateway to listen in TLS passthrough mode
- Add sidecar proxy for client to avoid rejecting unecrypted HTTP over HTTPS port (400 Bad Request: "Unencrypted HTTP protocol detected over encrypted port, could indicate a dangerous misconfiguration." - https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#scheme)
