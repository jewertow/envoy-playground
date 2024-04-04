1. Run an upstream server:
```shell
docker run -p 8000:80 kong/httpbin
```

2. Run Envoy:
```shell
./envoy-static -c envoy.yaml
```

3. Test a route allowed for admin:
```shell
curl -v -H "Authorization: Basic YWRtaW46YWRtaW4=" localhost:8080/ip
```
Expected output:
```
*   Trying 127.0.0.1:8080...
* Connected to localhost (127.0.0.1) port 8080 (#0)
> GET /ip HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/7.79.1
> Accept: */*
> Authorization: Basic YWRtaW46YWRtaW4=
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< server: envoy
< date: Thu, 04 Apr 2024 09:45:54 GMT
< content-type: application/json
< content-length: 29
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 1
< 
{
  "origin": "172.17.0.1"
}
* Connection #0 to host localhost left intact
```

Request with default credentials for filter:
```shell
curl -v -H "Authorization: Basic dXNlcjp0ZXN0" localhost:8080/ip
```
```       
*   Trying 127.0.0.1:8080...
* Connected to localhost (127.0.0.1) port 8080 (#0)
> GET /ip HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/7.79.1
> Accept: */*
> Authorization: Basic dXNlcjp0ZXN0
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 401 Unauthorized
< content-length: 66
< content-type: text/plain
< date: Thu, 04 Apr 2024 09:48:09 GMT
< server: envoy
< 
* Connection #0 to host localhost left intact
User authentication failed. Invalid username/password combination
```

4. Test a route with disabled authentication:
```shell
curl -v localhost:8080/headers
```
Expected output:
```                        
*   Trying 127.0.0.1:8080...
* Connected to localhost (127.0.0.1) port 8080 (#0)
> GET /headers HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/7.79.1
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< server: envoy
< date: Thu, 04 Apr 2024 09:45:02 GMT
< content-type: application/json
< content-length: 156
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 3
< 
{
  "headers": {
    "Accept": "*/*", 
    "Host": "localhost:8080", 
    "User-Agent": "curl/7.79.1", 
    "X-Envoy-Expected-Rq-Timeout-Ms": "15000"
  }
}
* Connection #0 to host localhost left intact
```

5. Test other routes with default auth settings:
```shell
curl -v -H "Authorization: Basic dXNlcjp0ZXN0" localhost:8080/user-agent
```
Expected output:
```
*   Trying 127.0.0.1:8080...
* Connected to localhost (127.0.0.1) port 8080 (#0)
> GET /user-agent HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/7.79.1
> Accept: */*
> Authorization: Basic dXNlcjp0ZXN0
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< server: envoy
< date: Thu, 04 Apr 2024 09:47:10 GMT
< content-type: application/json
< content-length: 34
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 1
< 
{
  "user-agent": "curl/7.79.1"
}
* Connection #0 to host localhost left intact
```

