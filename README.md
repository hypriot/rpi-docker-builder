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
`./builder.sh`
```bash
#!/bin/sh -x
docker run --rm=true --env-file=.env hypriot/rpi-docker-builder /builder.sh 1.5.0
```
