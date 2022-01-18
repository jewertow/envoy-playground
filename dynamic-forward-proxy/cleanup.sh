#!/bin/sh

for dir in "dynamic-forward-proxy" "client"; do
    rm -rf $dir/access.log
done

rm -rf dynamic-forward-proxy/envoy-*.pem
