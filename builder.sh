#!/bin/bash
set -e

# set env var
DOCKER_VERSION=$1
ARCH_VERSION=armv6hf
TAR_FILE=docker-$DOCKER_VERSION-linux-$ARCH_VERSION.tar.gz
DEB_FILE=docker-$DOCKER_VERSION-linux-$ARCH_VERSION.deb

# compile Docker
cd /src/docker
git checkout v$DOCKER_VERSION
export AUTO_GOPATH=1
GOARM=6 ./hack/make.sh dynbinary

# Create Debian package
cd /
tar czf $TAR_FILE -C /src/docker/bundles/$DOCKER_VERSION/dynbinary/ .

# Upload to S3 (using AWS CLI)
aws s3 cp $TAR_FILE s3://$AWS_BUCKET_NAME/docker/v$DOCKER_VERSION/
