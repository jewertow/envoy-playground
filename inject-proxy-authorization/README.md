## Inject Proxy-Authorization

1. Run configuration with Envoy 1.33
```shell
docker-compose -f current-implementation/docker-compose.yaml up
```

2. Send a request:
```shell
curl -v --resolve www.wikipedia.org:10000:127.0.0.1 https://www.wikipedia.org:10000/ -o /dev/null
```
