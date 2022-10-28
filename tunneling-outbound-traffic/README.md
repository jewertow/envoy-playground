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

### Test tunneling through sidecar proxy or gateway
```sh
docker exec -it client /bin/sh -c \
    "curl -v --resolve www.wikipedia.org:443:127.0.0.1 https://www.wikipedia.org/ | grep -o \"<title>.*</title>\""
```
As a result the following logs should appear:
```
client-sidecar    | [2022-10-27T10:57:44.645Z] DOWNSTREAM_REMOTE_ADDRESS=127.0.0.1:47110 UPSTREAM_HOST=172.21.0.3:3128 DOWNSTREAM_DIRECT_REMOTE_ADDRESS=127.0.0.1:47110 UPSTREAM_LOCAL_ADDRESS=172.21.0.2:40948 UPSTREAM_HOST=172.21.0.3:3128 UPSTREAM_REMOTE_ADDRESS=172.21.0.3:3128 [SNI: www.wikipedia.org] - - -" - 0 - - 
tunnel-proxy      | [2022-10-27T10:57:44.651Z] 172.21.0.2:40948 "CONNECT 91.198.174.192:443 - HTTP/1.1" - 200 - DC
```
