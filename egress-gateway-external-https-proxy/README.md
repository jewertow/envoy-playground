# PoC of envoy egress gateway that transparently acts the role of HTTPS proxy

#### How to run the demo
```sh
./setup-log-files.sh
docker-compose up
```

#### How to test proxy
```sh
export PROXY_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' egress)
docker exec -it client /bin/sh -c "curl -v --insecure --resolve www.wikipedia.org:443:$PROXY_IP https://www.wikipedia.org/ | grep -o \"<title>.*</title>\""
```
