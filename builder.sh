#!/bin/bash
set -e

# set env var
DOCKER_VERSION=$1
BUILD_REVISION=$2

# debian package versions
PACKAGE_NAME=docker-hypriot
PACKAGE_VERSION=$DOCKER_VERSION
PACKAGE_REVISION=$BUILD_REVISION
PACKAGE_ARCH=armhf
PACKAGE_ROOT=/pkg-debian
DEB_FILE=${PACKAGE_NAME}_${PACKAGE_VERSION}${PACKAGE_REVISION}_${PACKAGE_ARCH}.deb
TAR_FILE=${PACKAGE_NAME}-${DOCKER_VERSION}-${PACKAGE_REVISION}-${PACKAGE_ARCH}.tar.gz

# compile Docker from source
cd /src/docker
git checkout v$DOCKER_VERSION
export AUTO_GOPATH=1
GOARM=6 ./hack/make.sh dynbinary

# create tarball with Docker binaries
tar czf /$TAR_FILE -C /src/docker/bundles/$DOCKER_VERSION/dynbinary/ .

# create debian package
# --copy docker files
mkdir -p $PACKAGE_ROOT/etc/default/
cp /src/docker/contrib/init/sysvinit-debian/docker.default $PACKAGE_ROOT/etc/default/docker
mkdir -p $PACKAGE_ROOT/etc/init.d/
cp /src/docker/contrib/init/sysvinit-debian/docker $PACKAGE_ROOT/etc/init.d/docker
mkdir -p $PACKAGE_ROOT/lib/systemd/system/
cp /src/docker/contrib/init/systemd/docker.service $PACKAGE_ROOT/lib/systemd/system/
cp /src/docker/contrib/init/systemd/docker.socket $PACKAGE_ROOT/lib/systemd/system/
mkdir -p $PACKAGE_ROOT/usr/bin/
cp /src/docker/bundles/$DOCKER_VERSION/dynbinary/docker-$DOCKER_VERSION $PACKAGE_ROOT/usr/bin/docker
mkdir -p $PACKAGE_ROOT/usr/lib/docker/
cp /src/docker/bundles/$DOCKER_VERSION/dynbinary/dockerinit-$DOCKER_VERSION $PACKAGE_ROOT/usr/lib/docker/dockerinit

# --enable overlayfs by default
sed -i '/#DOCKER_OPTS/a \
DOCKER_OPTS="--storage-driver=overlay -D"' $PACKAGE_ROOT/etc/default/docker

# --get the total size of all package files
filesize=`du -sk /pkg-debian/ | cut -f1`
echo "Package size (uncompressed): $filesize kByte"

# --create control file
cat << EOF > /pkg-debian/DEBIAN/control
Package: $PACKAGE_NAME
Version: $PACKAGE_VERSION$PACKAGE_REVISION
Architecture: $PACKAGE_ARCH
Maintainer: Dieter Reuter <dieter@hypriot.com>
Installed-Size: $filesize
Depends: adduser, iptables
Conflicts: docker.io
Replaces: docker.io
Recommends: ca-certificates, cgroupfs-mount | cgroup-lite, git, xz-utils
Section: admin
Priority: optional
Homepage: https://github.com/docker/docker
Description: Docker for ARM devices, compiled and packaged by http://blog.hypriot.com
EOF

# --regenerate MD5 checksums for all files
(cd /pkg-debian; find . -type f ! -regex '.*.hg.*' ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -printf '%P ' | xargs md5sum > DEBIAN/md5sums)

# --use fakeroot to set owner/group to 0/0 (root/root)
fakeroot dpkg -b /pkg-debian/ /$DEB_FILE

if [ ! -z "${AWS_BUCKET_NAME}" ]; then
  # Upload to S3 (using AWS CLI)
  aws s3 cp /$TAR_FILE s3://$AWS_BUCKET_NAME/docker/bin/
  aws s3 cp /$DEB_FILE s3://$AWS_BUCKET_NAME/docker/deb/
fi
if [ -d /dist ]; then
  # Copy output to dist volume on host
  cp /$TAR_FILE /dist/
  cp /$DEB_FILE /dist/
fi
