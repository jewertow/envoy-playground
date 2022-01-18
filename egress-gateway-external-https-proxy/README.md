# PoC of envoy egress gateway that transparently acts the role of HTTPS proxy

#### How to run the demo
```sh
./setup-log-files.sh
docker-compose up
```

#### How to test proxy
```sh
docker exec client /bin/sh -c 'curl -v http://egress-gateway:80/ | grep -o "<title>.*</title>"'
```
