# rpi-docker-builder

This builder runs natively on a [Raspberry Pi with Docker 1.4](http://blog.hypriot.com/post/hypriotos-back-again-with-docker-on-arm/) or later, or on a [Scaleway C1 ARM server](https://www.scaleway.com) with a `Docker 1.5 Image`.

## How to use
*TL;DR*
```bash
git clone https://github.com/hypriot/rpi-docker-builder.git
cd rpi-docker-builder
./build.sh
./run-builder.sh
```

## Step 1: build the builder Docker Image
`./build.sh`
```bash
#!/bin/sh -x
docker build -t hypriot/rpi-docker-builder .
```

## Step 2: run builder for each Docker version
`./run-builder.sh`
```bash
#!/bin/sh -x
mkdir -p dist
touch .env
docker run --rm=true --env-file=.env -v $(pwd)/builder.sh:/builder.sh -v $(pwd)/pkg-debian:/pkg-debian -v $(pwd)/dist:/dist hypriot/rpi-docker-builder /builder.sh 1.6.0-rc7 -1
```

*Note:* if you like to build from trunk, just use version "1.6.0-dev" when calling ./builder.sh


## Results

### a) Get a local copy in `./dist/`
As soon as you'll use `run-builder.sh` you'll get a copy of the Debian package in a subdir `./dist/`.
```bash
ls -alh dist/
-rw-r--r-- 1 root root 5.4M Apr 16 19:41 docker-hypriot_1.6.0-1_armhf.deb
-rw-r--r-- 1 root root 5.5M Apr 16 19:41 docker-hypriot-1.6.0--1-armhf.tar.gz
```

### b) Automatically push to a S3 bucket
For this purpose you have to specifiy your S3 bucket and credentials in a local `.env` file. We just included a template `.env-template` file.

#### S3 ENV variables can be used from `.env` file or through ENV
`File=.env`
```
AWS_ACCESS_KEY_ID=ACCESS
AWS_SECRET_ACCESS_KEY=SECRET
AWS_DEFAULT_REGION=REGION
AWS_BUCKET_NAME=BUCKET
```


## Buy us a beer!

This FLOSS software is funded by donations only. Please support us to maintain and further improve it!

<a href="https://liberapay.com/Hypriot/donate"><img alt="Donate using Liberapay" src="https://liberapay.com/assets/widgets/donate.svg"></a>

