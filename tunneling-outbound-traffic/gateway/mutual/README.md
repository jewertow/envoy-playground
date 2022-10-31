## Generate certificates

```sh
curl https://raw.githubusercontent.com/jewertow/openssl-cert-gen/master/tls.sh | sh -s - --subject="cluster.local" --root-cert

curl https://raw.githubusercontent.com/jewertow/openssl-cert-gen/master/tls.sh | sh -s - --subject="client.default.svc.cluster.local" --root-cert-path=root-ca.crt --root-key-path=root-ca.key

curl https://raw.githubusercontent.com/jewertow/openssl-cert-gen/master/tls.sh | sh -s - --subject="egress-gateway.istio-system.svc.cluster.local" --root-cert-path=root-ca.crt --root-key-path=root-ca.key
```
