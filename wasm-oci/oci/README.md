## Envoy with WASM plugin fetched from AWS ECR

### Prerequisites

1. [wasm-to-oci](https://github.com/engineerd/wasm-to-oci)
2. envoy-static binary built from this [branch](https://github.com/jewertow/envoy/tree/wasm-oci-registry)

### Demo

1. Prepare variables:
```shell
ACCOUNT_ID=
REGION=
NAMESPACE=
```

2. Log in to the registry and prepare image pull secret:
```shell
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
cp ~/.docker/config.json /tmp/image-pull-secret.json
```

3. Download WASM plugin and push to the registry:
```shell
curl -v https://raw.githubusercontent.com/envoyproxy/examples/main/wasm-cc/lib/envoy_filter_http_wasm_example.wasm -o filter.wasm
```
```shell
wasm-to-oci push filter.wasm "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$NAMESPACE/envoy-wasm-http-filter:0.1"
```

4. Generate Envoy configuration for your account:
```shell
cat envoy-tmpl.yaml | sed -e "s/{{ACCOUNT_ID}}/$ACCOUNT_ID/g" -e "s/{{REGION}}/$REGION/g" -e "s/{{NAMESPACE}}/$NAMESPACE/g" > envoy.yaml
```

5. Run proxy:
```shell
./envoy-static -c envoy.yaml
```

5. Send a request:
```shell
curl -v localhost:8000/
```
Expected response:
```
* processing: localhost:8000/
*   Trying [::1]:8000...
* connect to ::1 port 8000 failed: Connection refused
*   Trying 127.0.0.1:8000...
* Connected to localhost (127.0.0.1) port 8000
> GET / HTTP/1.1
> Host: localhost:8000
> User-Agent: curl/8.2.1
> Accept: */*
> 
< HTTP/1.1 200 OK
< x-wasm-custom: FOO
< content-type: text/plain; charset=utf-8
< date: Wed, 16 Apr 2025 09:56:45 GMT
< server: envoy
< transfer-encoding: chunked
< 
* Connection #0 to host localhost left intact
Hello, world%        
```
