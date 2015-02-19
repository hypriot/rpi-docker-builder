#!/bin/sh -x
docker run -v /tmp:/tmp --rm=true -ti hypriot/rpi-docker-builder:1.5.0 /bin/bash -c 'cd /src/docker/bundles/1.5.0/dynbinary && tar cvfz /tmp/docker-1.5.0.tar.gz .'
cp /tmp/docker-1.5.0.tar.gz .
sudo rm -f /tmp/docker-1.5.0.tar.gz
