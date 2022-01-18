#!/bin/sh

for dir in "dynamic-forward-proxy" "client"; do
    touch $dir/access.log
    chmod 0446 $dir/access.log
done
