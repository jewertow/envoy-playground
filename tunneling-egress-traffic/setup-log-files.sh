#!/bin/sh

for dir in "gateway" "proxy"; do
    rm -rf $dir/access.log
    touch $dir/access.log
    chmod 0446 $dir/access.log
done
