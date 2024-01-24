1. Generate SSL certificates
```shell
curl https://raw.githubusercontent.com/jewertow/openssl-cert-gen/master/tls.sh | sh -s - --subject="untrusted-client.local"
rm root-ca.crt root-ca.key

curl https://raw.githubusercontent.com/jewertow/openssl-cert-gen/master/tls.sh | sh -s - --subject="local" --root-cert
curl https://raw.githubusercontent.com/jewertow/openssl-cert-gen/master/tls.sh | sh -s - --subject="client.local" --root-cert-path=root-ca.crt --root-key-path=root-ca.key
curl https://raw.githubusercontent.com/jewertow/openssl-cert-gen/master/tls.sh | sh -s - --subject="gateway.local" --root-cert-path=root-ca.crt --root-key-path=root-ca.key
```

2. Verify certificates:
```shell
openssl verify -verbose -CAfile root-ca.crt untrusted-client.local.crt
CN = untrusted-client.local
error 20 at 0 depth lookup: unable to get local issuer certificate
error untrusted-client.local.crt: verification failed
```
```shell
openssl verify -verbose -CAfile root-ca.crt client.local.crt
gateway.local.crt: OK
```

3. Run containers:
```shell
docker-compose up
```

4. Get proxy IP:
```shell
export PROXY_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' gateway)
```

5. Test mTLS connection with trusted certificates:
```shell
docker exec -it client /bin/sh -c "curl --insecure -v -H \"Host: httpbin\" \
    --key /etc/pki/tls/private/client.local.key \
    --cert /etc/pki/tls/certs/client.local.crt \
    https://$PROXY_IP:443/headers"
```

6. Test mTLS request with untrusted certificate:
```shell
docker exec -it client /bin/sh -c "curl --insecure -v -H \"Host: httpbin\" \
    --key /etc/pki/tls/private/untrusted-client.local.key \
    --cert /etc/pki/tls/certs/untrusted-client.local.crt \
    https://$PROXY_IP:443/headers"
```

7. Test simple HTTPS request:
```shell
docker exec -it client /bin/sh -c "curl --insecure -v -H \"Host: httpbin\" https://$PROXY_IP:443/headers"
```
