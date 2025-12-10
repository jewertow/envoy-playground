## Setup

### Generate TLS certificates

```bash
mkdir -p certs
# CA
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/ca.key -out certs/ca.crt \
  -subj "/CN=example.com Root CA/O=example.com"

# srv1
openssl req -new -nodes -newkey rsa:2048 \
  -keyout certs/srv1.key -out certs/srv1.csr \
  -subj "/CN=srv1.example.com/O=example.com"
openssl x509 -req -in certs/srv1.csr \
  -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial \
  -out certs/srv1.crt -days 365 \
  -extfile <(printf "subjectAltName=DNS:srv1.example.com")

# srv2
openssl req -new -nodes -newkey rsa:2048 \
  -keyout certs/srv2.key -out certs/srv2.csr \
  -subj "/CN=srv2.example.com/O=example.com"
openssl x509 -req -in certs/srv2.csr \
  -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial \
  -out certs/srv2.crt -days 365 \
  -extfile <(printf "subjectAltName=DNS:srv2.example.com")
```
```bash
chmod o+r certs/ca.key certs/srv1.key certs/srv2.key
```

### Start the containers

```bash
docker compose up
```

## Testing

### HTTP (port 10000)

From the client container:

```bash
docker exec -it client curl http://envoy:10000
```

### HTTPS with specific SNI (port 10443)

The HTTPS listener uses SNI-based filter chain matching. You can test different filter chains by specifying different SNI values.

```bash
SRV_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' envoy-static-response)
```

Test the srv1.example.com filter chain:

```bash
docker exec -it client curl -vk --cacert /certs/ca.crt --resolve srv1.example.com:10443:$SRV_IP https://srv1.example.com:10443
```

Test the srv2.example.com filter chain:

```bash
docker exec -it client curl -vk --cacert /certs/ca.crt --resolve srv2.example.com:10443:$SRV_IP https://srv2.example.com:10443
```

Test with a different SNI to hit the fallback filter chain:

```bash
docker exec -it client curl -vk --cacert /certs/ca.crt https://envoy:10443
```
