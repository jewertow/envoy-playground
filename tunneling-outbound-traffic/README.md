# Tunneling traffic via TcpProxy

## Usage

### Generate SSL certificates
```sh
curl https://raw.githubusercontent.com/jewertow/openssl-cert-gen/master/tls.sh | sh -s - --subject="tunnel-proxy"
```

### Run containers
```sh
docker-compose up
```

### Test CONNECT proxy
```sh
docker exec -it client /bin/sh -c \
    "curl -v --proxy-insecure --proxy https://tunnel-proxy:3128 https://www.wikipedia.org/ | grep -o \"<title>.*</title>\""
```
As a result the following line should be logged:
```
tunnel-proxy  | [2022-10-27T10:06:27.392Z] 172.20.0.2:37258 "CONNECT 91.198.174.192:443 - HTTP/1.1" - 200 - DC
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
