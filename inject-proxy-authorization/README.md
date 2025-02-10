## Inject Proxy-Authorization header to upstream HTTPS proxy

### Deploy proxies

#### 1. Envoy v1.33 - TcpProxy and `headers_to_add` with plain credentials

```shell
docker-compose -f tunneling_config.headers_to_add/docker-compose.yaml up
```

#### 2. Envoy v1.34-dev - extended TcpProxy with credential injector

```shell
docker-compose -f envoy.extensions.http.injected_credentials/docker-compose.yaml up
```

#### 3. Envoy v1.34-dev - credential injector dual filter

```shell
docker-compose -f envoy.filters.http.upstream.credential_injector/docker-compose.yaml up
```

### Send a request:

```shell
curl -v --resolve www.wikipedia.org:10000:127.0.0.1 https://www.wikipedia.org:10000/ -o /dev/null
```

