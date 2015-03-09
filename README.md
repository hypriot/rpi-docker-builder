# rpi-docker-builder

## S3 ENV variables can be used from `.env` file or through ENV
`File=.env`
```
AWS_ACCESS_KEY_ID=ACCESS
AWS_SECRET_ACCESS_KEY=SECRET
AWS_DEFAULT_REGION=REGION
AWS_BUCKET_NAME=BUCKET
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
docker run --rm=true --env-file=.env -v $(pwd)/builder.sh:/builder.sh -v $(pwd)/pkg-debian:/pkg-debian hypriot/rpi-docker-builder /builder.sh 1.5.0 -7
```

*Note:* if you like to build from trunk, just use version "1.5.0-dev" when calling ./builder.sh
