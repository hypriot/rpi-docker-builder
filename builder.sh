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
git checkout master
git fetch -q --all -p
git checkout v$DOCKER_VERSION
export AUTO_GOPATH=1
#+++FIX: 1.7.0-rc1, 1.7.0-rc2, 1.7.0-rc3
#rm -f /src/docker/vendor/src/github.com/vishvananda/netns/netns_linux_amd.go
#---FIX
#+++FIX: 1.7.0
# fixes https://github.com/docker/docker/issues/14184
# see https://github.com/vishvananda/netns/pull/8
#sed -i s/374/375/g /src/docker/vendor/src/github.com/vishvananda/netns/netns_linux_arm.go
#---FIX
#+++FIX: 1.8.0-rc3
#echo "Applying PR opencontainers/runc#70 ..."
#pushd vendor/src/github.com/opencontainers
#rm -rf runc
#git clone --depth 1 --branch seccomp https://github.com/mheon/runc.git
#popd
#---FIX
#+++FIX: 1.8.2
#echo "Applying PR opencontainers/runc#70 ..."
#pushd vendor/src/github.com/opencontainers
#rm -rf runc
#git clone --branch v0.0.3 https://github.com/opencontainers/runc.git
#cd runc
#git cherry-pick 2ae581ae62f26c7c253d23f4dad1a497ba98f7d4
#git cherry-pick 8da24a5447c4d47fd895c7251ab8ed6d2b6f459f
#git cherry-pick 59264040bd9668e1434abb1a1057989ca623b437
#git cherry-pick a6b73dbc733abee71c1df28836b04d8b6c4f4f18
#cd ..
#popd
#mkdir -p vendor/src/github.com/seccomp
#pushd vendor/src/github.com/seccomp
#git clone --depth 1 https://github.com/seccomp/libseccomp-golang.git
#popd
#mkdir -p /src/docker/vendor/src/github.com/coreos
#pushd /src/docker/vendor/src/github.com/coreos
#rm -rf go-systemd
#git clone --depth 1 https://github.com/coreos/go-systemd
#popd
#---FIX
#+++FIX: 1.8.2 (by @umiddelberg)
#set -x
#mv vendor/src/github.com/opencontainers/runc/libcontainer/seccomp/{jump_amd64.go,jump_linux.go}
#sed -i 's/,amd64//' vendor/src/github.com/opencontainers/runc/libcontainer/seccomp/jump_linux.go
#set +x
#---FIX
GOARM=6 ./hack/make.sh dynbinary

# create tarball with Docker binaries
tar czf /$TAR_FILE -C /src/docker/bundles/$DOCKER_VERSION/dynbinary/ .

# create debian package
# --copy docker files
mkdir -p $PACKAGE_ROOT/etc/default/
cp /src/docker/contrib/init/sysvinit-debian/docker.default $PACKAGE_ROOT/etc/default/docker
mkdir -p $PACKAGE_ROOT/etc/init.d/
# cp /src/docker/contrib/init/sysvinit-debian/docker $PACKAGE_ROOT/etc/init.d/docker
mkdir -p $PACKAGE_ROOT/lib/systemd/system/
# cp /src/docker/contrib/init/systemd/docker.service $PACKAGE_ROOT/lib/systemd/system/
cp /src/docker/contrib/init/systemd/docker.socket $PACKAGE_ROOT/lib/systemd/system/
mkdir -p $PACKAGE_ROOT/etc/bash_completion.d
cp /src/docker/contrib/completion/bash/docker $PACKAGE_ROOT/etc/bash_completion.d/docker
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
