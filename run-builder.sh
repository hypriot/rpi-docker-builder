#!/bin/sh -x
docker run --rm=true --env-file=.env hypriot/rpi-docker-builder /builder.sh 1.5.0 hypriot-6
