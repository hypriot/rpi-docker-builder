#!/bin/sh -x
mkdir -p dist
touch .env
docker run --rm=true --env-file=.env -v $(pwd)/builder.sh:/builder.sh -v $(pwd)/pkg-debian:/pkg-debian -v $(pwd)/dist:/dist hypriot/rpi-docker-builder /builder.sh 1.9.0 -2
