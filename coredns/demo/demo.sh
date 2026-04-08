#!/bin/bash

echo "Starting CoreDNS..."
docker run -d --name coredns-demo -p 1053:53/udp -v $(pwd)/coredns/demo/Corefile:/Corefile coredns/coredns:latest -conf /Corefile

echo "Waiting for CoreDNS to start..."
sleep 3

echo "Querying for example.com:"
dig @localhost -p 1053 example.com

echo "Stopping and removing CoreDNS container..."
docker stop coredns-demo && docker rm coredns-demo
