### Generate SSL certificates
```shell
curl https://raw.githubusercontent.com/jewertow/openssl-cert-gen/master/tls.sh | sh -s - --subject="local" --root-cert
curl https://raw.githubusercontent.com/jewertow/openssl-cert-gen/master/tls.sh | sh -s - --subject="client.local" --root-cert-path=root-ca.crt --root-key-path=root-ca.key
curl https://raw.githubusercontent.com/jewertow/openssl-cert-gen/master/tls.sh | sh -s - --subject="gateway.local" --root-cert-path=root-ca.crt --root-key-path=root-ca.key
```

1. Deploy:
```shell
docker-compose up
```

2. Test mTLS request:
```shell
export PROXY_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' gateway)
```
```shell
docker exec -it client /bin/sh -c "curl --insecure -v -H \"Host: httpbin\" \
    --key /etc/pki/tls/private/client.local.key \
    --cert /etc/pki/tls/certs/client.local.crt \
    https://$PROXY_IP:443/headers"
```