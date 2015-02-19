#!/bin/sh -x
tar xvf docker-1.5.0.tar.gz ./docker-1.5.0 ./dockerinit-1.5.0
sudo service docker stop
sudo cp ./docker-1.5.0 /usr/bin/docker
sudo cp ./dockerinit-1.5.0 /usr/lib/docker/dockerinit
sudo service docker start
