# Tunneling outbound traffic to HTTP services

This directory contains prototype implementation of tunneling TCP over HTTP with HttpConnectionManager
and internal UDS listener for tunneling.

## Usage

### Generate SSL certificates
For tunnel proxy (tunneling TCP over HTTP with HTTP CONNECT)
```sh
curl https://raw.githubusercontent.com/jewertow/openssl-cert-gen/master/tls.sh | sh -s - --subject="tunnel-proxy"
```
For mTLS samples
```sh
curl https://raw.githubusercontent.com/jewertow/openssl-cert-gen/master/tls.sh | sh -s - --subject="cluster.local" --root-cert

curl https://raw.githubusercontent.com/jewertow/openssl-cert-gen/master/tls.sh | sh -s - --subject="client.default.svc.cluster.local" --root-cert-path=root-ca.crt --root-key-path=root-ca.key

curl https://raw.githubusercontent.com/jewertow/openssl-cert-gen/master/tls.sh | sh -s - --subject="egress-gateway.istio-system.svc.cluster.local" --root-cert-path=root-ca.crt --root-key-path=root-ca.key

mv *.cluster.local.* root-ca.* gateway/mutual
```

### Setup enviroment
For tunneling through a sidecar proxy:
```sh
docker-compose -f sidecar/docker-compose.yaml up
```
For tunneling through a TLS passthrough gateway:
```sh
docker-compose -f gateway/passthrough/docker-compose.yaml up
```
For tunneling through a mutual TLS gateway:
```sh
docker-compose -f gateway/mutual/docker-compose.yaml up
```

### Test tunneling with TLS origination through sidecar proxy or gateway
```sh
docker exec -it client /bin/sh -c "curl -v http://www.wikipedia.org/ | grep -o \"<title>.*</title>\""
```
As a result the following logs should appear:
```log
client-sidecar    | [2022-10-31T18:15:13.334Z] 172.25.0.2:53300 "GET 172.25.0.3:443 / HTTP/1.1" - 200 - -
egress-gateway    | [2022-10-31T18:15:13.335Z] DRA=172.25.0.2:34362 UH=@/tunnel-0.0.0.0_443 ULA=- [SNI=egress-gateway]" - 0 - - 
egress-gateway    | [2022-10-31T18:15:13.335Z] [UDS] DRA=@/tunnel-0.0.0.0_443 UH=172.25.0.4:3128 ULA=172.25.0.3:37936 [SNI=www.wikipedia.org]" - 0 - - 
tunnel-proxy      | [2022-10-31T18:15:13.343Z] DRA=172.25.0.3:37936 "CONNECT 91.198.174.192:443 - HTTP/1.1" - 200 - DC
```
