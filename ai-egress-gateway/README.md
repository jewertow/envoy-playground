# Envoy AI Gateway and AWS Bedrock Demo

1. Prepare environment:

    ```shell
    export AWS_REGION=
    export AWS_ACCOUNT_ID=
    export BEDROCK_MODEL_ID=us.meta.llama3-2-1b-instruct-v1:0
    export AWS_ACCESS_KEY_ID=
    export AWS_SECRET_ACCESS_KEY=
    ```

## No AI gateway

1. Create a config map and a secret with required variables:

    ```shell
    kubectl create namespace model-aware-app
    ```
    ```shell
    kubectl create cm bedrock-config -n model-aware-app \
      --from-literal=AWS_REGION=$AWS_REGION \
      --from-literal=AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID \
      --from-literal=BEDROCK_MODEL_ID=$BEDROCK_MODEL_ID
    ```
    ```shell
    kubectl create secret generic aws-creds -n model-aware-app \
      --from-literal=AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
      --from-literal=AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
    ```

1. Deploy bedrock client:

    ```shell
    kubectl apply -n model-aware-app -f - <<EOF
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: bedrock-client
    spec:
      selector:
        matchLabels:
          app: bedrock-client
      template:
        metadata:
          labels:
            app: bedrock-client
        spec:
          containers:
          - name: bedrock-client
            image: quay.io/jewertow/bedrock-client:latest
            env:
            - name: AWS_ACCOUNT_ID
              valueFrom:
                configMapKeyRef:
                  name: bedrock-config
                  key: AWS_ACCOUNT_ID
            - name: AWS_REGION
              valueFrom:
                configMapKeyRef:
                  name: bedrock-config
                  key: AWS_REGION
            - name: BEDROCK_MODEL_ID
              valueFrom:
                configMapKeyRef:
                  name: bedrock-config
                  key: BEDROCK_MODEL_ID
            - name: AWS_ACCESS_KEY_ID
              valueFrom:
                secretKeyRef:
                  name: aws-creds
                  key: AWS_ACCESS_KEY_ID
            - name: AWS_SECRET_ACCESS_KEY
              valueFrom:
                secretKeyRef:
                  name: aws-creds
                  key: AWS_SECRET_ACCESS_KEY
    EOF
    ```

1. Send a request to the LLM:

   ```shell
   kubectl exec -n model-aware-app deploy/bedrock-client -- curl -v "localhost:8080/ask?prompt=how%20can%20I%20write%20Hello%20world%20in%20Java"
   ```

## AI Gateway

1. **If you use OpenShift**, enable anyuid SCC for pre-install hooks and the control plane:

   ```shell
   oc adm policy add-scc-to-group anyuid system:serviceaccounts:default
   oc adm policy add-scc-to-group anyuid system:serviceaccounts:envoy-gateway-system
   ```

1. Install Envoy Gateway and AI Gateway control planes:

   ```shell
   helm upgrade -i eg oci://docker.io/envoyproxy/gateway-helm \
       --version v1.4.1 \
       --namespace envoy-gateway-system \
       --create-namespace

   helm upgrade -i aieg-crd oci://docker.io/envoyproxy/ai-gateway-crds-helm \
       --version v0.2.1 \
       --namespace envoy-ai-gateway-system \
       --create-namespace
   
   helm upgrade -i aieg oci://docker.io/envoyproxy/ai-gateway-helm \
       --version v0.2.1 \
       --namespace envoy-ai-gateway-system \
       --create-namespace
   ```

1. Deploy an egress gateway:

   ```shell
   kubectl apply -f - <<EOF
   apiVersion: gateway.networking.k8s.io/v1
   kind: GatewayClass
   metadata:
     name: envoy-ai-gateway-basic
   spec:
     controllerName: gateway.envoyproxy.io/gatewayclass-controller
   ---
   apiVersion: gateway.networking.k8s.io/v1
   kind: Gateway
   metadata:
     name: envoy-ai-gateway-basic
     namespace: default
   spec:
     gatewayClassName: envoy-ai-gateway-basic
     infrastructure:
       parametersRef:
         group: gateway.envoyproxy.io
         kind: EnvoyProxy
         name: egress-gateway
     listeners:
     - name: http
       protocol: HTTP
       port: 80
   ---
   apiVersion: gateway.envoyproxy.io/v1alpha1
   kind: EnvoyProxy
   metadata:
     name: egress-gateway
     namespace: default
   spec:
     provider:
       type: Kubernetes
       kubernetes:
         envoyService:
           type: ClusterIP
           name: ai-gateway
   EOF
   ```

1. Create secret:

   ```shell
   kubectl apply -f - <<EOF
   apiVersion: v1
   kind: Secret
   metadata:
     name: envoy-ai-gateway-basic-aws-credentials
     namespace: default
   type: Opaque
   stringData:
     credentials: |
       [default]
       aws_access_key_id = ${AWS_ACCESS_KEY_ID}
       aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}
   EOF
   ```

1. Configure AI Gateway routing:

   ```shell
   kubectl apply -f - <<EOF
   apiVersion: aigateway.envoyproxy.io/v1alpha1
   kind: AIGatewayRoute
   metadata:
     name: envoy-ai-gateway-basic
     namespace: default
   spec:
     schema:
       name: OpenAI
     targetRefs:
     - name: envoy-ai-gateway-basic
       kind: Gateway
       group: gateway.networking.k8s.io
     rules:
     - matches:
       - headers:
         - type: Exact
           name: x-ai-eg-model
           value: us.meta.llama3-2-1b-instruct-v1:0
       backendRefs:
       - name: envoy-ai-gateway-basic-aws
   ---
   apiVersion: aigateway.envoyproxy.io/v1alpha1
   kind: AIServiceBackend
   metadata:
     name: envoy-ai-gateway-basic-aws
     namespace: default
   spec:
     schema:
       name: AWSBedrock
     backendRef:
       name: envoy-ai-gateway-basic-aws
       kind: Backend
       group: gateway.envoyproxy.io
     backendSecurityPolicyRef:
       name: envoy-ai-gateway-basic-aws-credentials
       kind: BackendSecurityPolicy
       group: aigateway.envoyproxy.io
   ---
   apiVersion: aigateway.envoyproxy.io/v1alpha1
   kind: BackendSecurityPolicy
   metadata:
     name: envoy-ai-gateway-basic-aws-credentials
     namespace: default
   spec:
     type: AWSCredentials
     awsCredentials:
       region: us-east-1
       credentialsFile:
         secretRef:
           name: envoy-ai-gateway-basic-aws-credentials
   ---
   apiVersion: gateway.envoyproxy.io/v1alpha1
   kind: Backend
   metadata:
     name: envoy-ai-gateway-basic-aws
     namespace: default
   spec:
     endpoints:
     - fqdn:
         hostname: bedrock-runtime.us-east-1.amazonaws.com
         port: 443
   ---
   apiVersion: gateway.networking.k8s.io/v1alpha3
   kind: BackendTLSPolicy
   metadata:
     name: envoy-ai-gateway-basic-aws-tls
     namespace: default
   spec:
     targetRefs:
     - group: gateway.envoyproxy.io
       kind: Backend
       name: envoy-ai-gateway-basic-aws
     validation:
       wellKnownCACertificates: "System"
       hostname: bedrock-runtime.us-east-1.amazonaws.com
   EOF
   ```

1. Send a test request to the AI gateway:

   ```shell
   kubectl exec -n model-aware-app deploy/bedrock-client -- curl -H "Content-Type: application/json" \
       -d '{
           "model": "us.meta.llama3-2-1b-instruct-v1:0",
           "messages": [
               {
                   "role": "user",
                   "content": "Hi."
               }
           ]
       }' \
       http://ai-gateway.envoy-gateway-system/v1/chat/completions
   ```

## TODO

Response:
```
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0*   Trying 172.30.177.10...
* TCP_NODELAY set
* Connected to ai-gateway.envoy-gateway-system (172.30.177.10) port 80 (#0)
> POST /v1/chat/completions HTTP/1.1
> Host: ai-gateway.envoy-gateway-system
> User-Agent: curl/7.61.1
> Accept: */*
> Content-Type: application/json
> Content-Length: 202
> 
} [202 bytes data]
* upload completely sent off: 202 out of 202 bytes
< HTTP/1.1 500 Internal Server Error
< date: Tue, 24 Jun 2025 21:56:49 GMT
< connection: close
< content-length: 0
< 
100   202    0     0  100   202      0  33666 --:--:-- --:--:-- --:--:-- 33666
* Closing connection 0
```

Logs from ai-gateway proxy:
```
{":authority":"ai-gateway.envoy-gateway-system","bytes_received":0,"bytes_sent":0,"connection_termination_details":null,"downstream_local_address":"10.131.0.25:10080","downstream_remote_address":"10.129.2.19:40482","duration":0,"method":"POST","protocol":"HTTP/1.1","requested_server_name":null,"response_code":500,"response_code_details":"direct_response","response_flags":"-","route_name":"httproute/default/envoy-ai-gateway-basic/rule/1/match/0/*","start_time":"2025-06-24T21:26:50.836Z","upstream_cluster":null,"upstream_host":null,"upstream_local_address":null,"upstream_transport_failure_reason":null,"user-agent":"curl/7.61.1","x-envoy-origin-path":"/v1/chat/completions","x-envoy-upstream-service-time":null,"x-forwarded-for":"10.129.2.19","x-request-id":"65280e53-8a89-467a-b0e4-cc18a1a2cb06"}
{":authority":"172.30.177.10","bytes_received":0,"bytes_sent":0,"connection_termination_details":null,"downstream_local_address":"10.131.0.25:10080","downstream_remote_address":"10.129.2.19:36446","duration":0,"method":"POST","protocol":"HTTP/1.1","requested_server_name":null,"response_code":500,"response_code_details":"direct_response","response_flags":"-","route_name":"httproute/default/envoy-ai-gateway-basic/rule/1/match/0/*","start_time":"2025-06-24T21:31:31.910Z","upstream_cluster":null,"upstream_host":null,"upstream_local_address":null,"upstream_transport_failure_reason":null,"user-agent":"curl/7.61.1","x-envoy-origin-path":"/v1/chat/completions","x-envoy-upstream-service-time":null,"x-forwarded-for":"10.129.2.19","x-request-id":"40c949a8-be09-4a4c-8e80-90324834d859"}
{":authority":"ai-gateway.envoy-gateway-system.svc.cluster.local","bytes_received":0,"bytes_sent":0,"connection_termination_details":null,"downstream_local_address":"10.131.0.25:10080","downstream_remote_address":"10.129.2.19:42310","duration":0,"method":"POST","protocol":"HTTP/1.1","requested_server_name":null,"response_code":500,"response_code_details":"direct_response","response_flags":"-","route_name":"httproute/default/envoy-ai-gateway-basic/rule/1/match/0/*","start_time":"2025-06-24T21:36:03.753Z","upstream_cluster":null,"upstream_host":null,"upstream_local_address":null,"upstream_transport_failure_reason":null,"user-agent":"curl/7.61.1","x-envoy-origin-path":"/v1/chat/completions","x-envoy-upstream-service-time":null,"x-forwarded-for":"10.129.2.19","x-request-id":"526a6769-6db5-401b-9dde-862b47be2ef0"}
```
