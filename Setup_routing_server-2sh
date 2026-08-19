#!/bin/bash

sudo ip route replace \
    192.168.2.0/24 \
    via 10.0.2.4 \
    dev enp0s3

echo
echo "Route:"
ip route get 192.168.2.2
