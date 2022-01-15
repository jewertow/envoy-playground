#!/bin/sh

for dir in "gateway" "proxy"; do
    touch $dir/access.log
    chmod 0446 $dir/access.log
done
