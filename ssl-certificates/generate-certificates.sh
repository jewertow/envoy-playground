#!/bin/sh

SSL_COMMON_NAME=$1
if [ -z "${SSL_COMMON_NAME}" ];
then
    echo "SSL_COMMON_NAME not provided. Please run scipt as follows: './generate-certificates.sh <your-CN>'"
    exit 1
fi

docker build --build-arg SSL_COMMON_NAME=${SSL_COMMON_NAME} -t envoy-certgen:latest .

docker container create --name certgen envoy-certgen:latest
docker container cp certgen:/etc/pki/CA/envoy-ca-cert.pem ./envoy-ca-cert.pem
docker container cp certgen:/etc/pki/tls/private/envoy-key.pem ./envoy-key.pem
docker container cp certgen:/etc/pki/tls/certs/envoy-cert.pem ./envoy-cert.pem
docker container rm -f certgen

chmod +r envoy-key.pem
