# Tunneling outbound traffic

This directory contains prototype implementation of tunneling TCP over HTTP with internal UDS listeners used to tunnel traffic.
Internal tunneling listeners solve the problem of collecting metrics per requested cluster, instead of only for tunneling proxy.
Another advantage over the current implementation is the ability to use `%REQUESTED_SERVER_NAME%` as `tunneling_config.hostname`
in TLS-terminated gateways (look at `gateway/mutual/gateway.yaml`) that cannot be used in the current implementation.
A potential disadvantage is that there is no ability to use `%DOWNSTREAM_LOCAL_ADDRESS%`, as original destination,
in the `tunneling_config.hostname` when tunneling is performed by a sidecar.

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

### Test tunneling through sidecar proxy or gateway
```sh
docker exec -it client /bin/sh -c "curl -v https://www.wikipedia.org/ | grep -o \"<title>.*</title>\""
```
As a result the following logs should appear:
```log
client-sidecar    | [2022-10-31T10:49:17.017Z] DRA=172.22.0.2:41644 UH=172.22.0.3:443 ULA=172.22.0.2:52996 [SNI=www.wikipedia.org, ORIG_DST=91.198.174.192:443]" - 0 - -
egress-gateway    | [2022-10-31T10:49:17.028Z] DRA=172.22.0.2:52996 UH=172.22.0.4:3128 ULA=172.22.0.3:59078 [SNI=www.wikipedia.org]" - 0 - -
tunnel-proxy      | [2022-10-31T10:49:17.030Z] DRA=172.22.0.3:59078 "CONNECT 91.198.174.192:443 - HTTP/1.1" - 200 - DC
```

### Known issues
1. Original destination is not available in subsequent listeners. How to pass it to a next listener? Is it possible to do it with dynamic metadata?
```log
client-sidecar    | [2022-10-31T13:06:11.307Z] DRA=172.23.0.2:60904 UH=@/tunnel-0.0.0.0_443 ULA=- [SNI=www.wikipedia.org, ORIG_DST=91.198.174.192:443]" - 0 - -
client-sidecar    | [2022-10-31T13:06:11.331Z] [UDS] DRA=@/tunnel-0.0.0.0_443 UH=172.23.0.3:3128 ULA=172.23.0.2:40160 [SNI=www.wikipedia.org, ORIG_DST=@/tunnel-0.0.0.0_443]" - 0 - -
tunnel-proxy      | [2022-10-31T13:06:11.335Z] DRA=172.23.0.2:40160 "CONNECT 91.198.174.192:443 - HTTP/1.1" - 200 - DC
```

### Test tunneling via proxy without iptables and Envoy proxies
```sh
docker exec -it client /bin/sh -c \
    "curl -v --proxy-insecure --proxy https://tunnel-proxy:3128 https://www.wikipedia.org/ | grep -o \"<title>.*</title>\""
```
