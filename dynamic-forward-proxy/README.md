# Demo of Envoy dynamic forward proxy

#### How to run the demo
##### Create SSL certificates
```sh
cd dynamic-forward-proxy
./generate-certificates.sh
cd ..
```
##### Run containers
```sh
./setup-log-files.sh
docker-compose up
```

#### How to test proxy
```sh
export PROXY_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dynamic-proxy)
docker exec -it client /bin/sh -c "curl -v --insecure --resolve www.wikipedia.org:443:$PROXY_IP https://www.wikipedia.org/ | grep -o \"<title>.*</title>\""
```
