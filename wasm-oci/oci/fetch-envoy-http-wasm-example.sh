#!/bin/bash

set -e

OCI_MANIFEST_SCHEMA="application/vnd.oci.image.manifest.v1+json"

# Get authentication token (required only for docker?)
curl -v https://auth.docker.io/token\?service\=registry.docker.io\&scope\=repository:jewe/envoy-filter-http-wasm-example:pull -o auth.json
TOKEN=$(jq '.access_token' -r auth.json)

# Get manifest
curl -v -o manifest.json \
	-H "Authorization: Bearer $TOKEN" \
	-H "Accept: $OCI_MANIFEST_SCHEMA" \
	https://registry-1.docker.io/v2/jewe/envoy-filter-http-wasm-example/manifests/0.0.1

# Get wasm digest
WASM_DIGEST=$(jq -r '.layers[] | select(.mediaType == "application/vnd.wasm.content.layer.v1+wasm") | .digest' manifest.json)
echo "WASM digest: $WASM_DIGEST"
curl -vL -o filter.wasm \
	-H "Authorization: Bearer $TOKEN" \
	"https://registry-1.docker.io/v2/jewe/envoy-filter-http-wasm-example/blobs/$WASM_DIGEST"
