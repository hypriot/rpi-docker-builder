
# Pull base image
FROM hypriot/rpi-golang:1.4.2
MAINTAINER Dieter Reuter <dieter@hypriot.com>

# Install dependencies
RUN apt-get update && apt-get install -y \
    btrfs-tools \
    libsqlite3-dev \
    libdevmapper-dev \
    python-pip \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Install AWS CLI
RUN pip install awscli

# Clone Docker
ENV DOCKER_VERSION 1.5.0
ENV TAR_FILE /docker-$DOCKER_VERSION.tar.gz
ENV DEB_FILE /docker-$DOCKER_VERSION-armv6hf.deb
RUN \
    mkdir -p /src && \
    cd /src && \
    git clone https://github.com/docker/docker.git && \
    cd docker && \
    git checkout v$DOCKER_VERSION

# Patch Docker for ARM 32bit
ADD files/version.h /usr/include/btrfs/version.h

# Compile Docker from source
RUN \
    export AUTO_GOPATH=1 && \
    cd /src/docker && \
    GOARM=6 ./hack/make.sh dynbinary

# Create Debian package
RUN \
    tar czf $TAR_FILE -C /src/docker/bundles/$DOCKER_VERSION/dynbinary/ .

# Upload to S3 (using AWS CLI)
printf "$ACCESS_KEY\n$SECRET_KEY\n$REGION_NAME\n\n" | aws configure
aws s3 cp $TAR_FILE s3://$BUCKET_NAME/docker/v$DOCKER_VERSION/

# Define working directory
WORKDIR /data

# Define default command
CMD ["bash"]
