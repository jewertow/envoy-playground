### Envoy as dynamic forward proxy

#### Create SSL certificate
```sh
curl https://raw.githubusercontent.com/jewertow/openssl-cert-gen/master/tls.sh | sh -s - --subject="dynamic-proxy"
```

#### Run containers
```sh
docker-compose up
```

#### Test proxy
```sh
export PROXY_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dynamic-proxy)
docker exec -it client /bin/sh -c "curl -v --insecure --resolve www.wikipedia.org:443:$PROXY_IP https://www.wikipedia.org/ | grep -o \"<title>.*</title>\""
```
