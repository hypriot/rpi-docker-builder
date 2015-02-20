
# Pull base image
FROM hypriot/rpi-golang:1.4.2
MAINTAINER Dieter Reuter <dieter@hypriot.com>

# Install dependencies
RUN apt-get update && apt-get install -y \
    btrfs-tools \
    libsqlite3-dev \
    libdevmapper-dev \
    fakeroot \
    python-pip \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Install AWS CLI
RUN pip install awscli

# Clone Docker
RUN \
    mkdir -p /src && \
    cd /src && \
    git clone https://github.com/docker/docker.git

# Add Docker specific files
ADD files/version.h /usr/include/btrfs/version.h

# Debian package template
ADD pkg-debian /pkg-debian

# Builder script
COPY builder.sh /
