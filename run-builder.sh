#!/bin/sh -x
docker run --rm=true --env-file=.env -v $(pwd)/builder.sh:/builder.sh -v $(pwd)/pkg-debian:/pkg-debian hypriot/rpi-docker-builder /builder.sh 1.5.0 -7
