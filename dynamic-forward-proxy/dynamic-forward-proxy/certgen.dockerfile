FROM alpine:3.15.0

RUN apk add openssl
RUN mkdir /etc/pki
RUN mkdir /etc/pki/CA
RUN mkdir /etc/pki/tls/
RUN mkdir /etc/pki/tls/private
RUN mkdir /etc/pki/tls/certs

# Create private key and X509 certificate for CA
# TODO: change .pem extensions to .key and .crt
RUN openssl genrsa 2048 > /etc/pki/CA/envoy-ca-key.pem
RUN openssl req \
    -subj "/O=None/CN=dynamic-forward-proxy" \
    -addext "subjectAltName=DNS:dynamic-forward-proxy" \
    -new -x509 -nodes -days 36500 \
    -key /etc/pki/CA/envoy-ca-key.pem \
    -out /etc/pki/CA/envoy-ca-cert.pem

# Create private key and X509 certificate for a server
RUN openssl req \
    -subj "/O=None/CN=dynamic-forward-proxy" \
    -addext "subjectAltName=DNS:dynamic-forward-proxy" \
    -newkey rsa:2048 -nodes -days 365000 \
    -keyout /etc/pki/tls/private/envoy-key.pem \
    -out /etc/pki/tls/private/envoy-cert-req.pem
RUN openssl x509 \
    -req -days 365000 -set_serial 01 \
    -in /etc/pki/tls/private/envoy-cert-req.pem \
    -out /etc/pki/tls/certs/envoy-cert.pem \
    -CA /etc/pki/CA/envoy-ca-cert.pem \
    -CAkey /etc/pki/CA/envoy-ca-key.pem
