#!/bin/sh

docker build -t certgen-dynamic-forward-proxy:latest -f certgen.dockerfile .

docker container create --name certgen certgen-dynamic-forward-proxy:latest
docker container cp certgen:/etc/pki/CA/envoy-ca-cert.pem ./envoy-ca-cert.pem
docker container cp certgen:/etc/pki/tls/private/envoy-key.pem ./envoy-key.pem
docker container cp certgen:/etc/pki/tls/certs/envoy-cert.pem ./envoy-cert.pem
docker container rm -f certgen

chmod +r envoy-key.pem
