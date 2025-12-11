#!/usr/bin/env bash

REMOTE_DIR="/usr/local/etc/nginx"

ssh demo "mkdir -p $REMOTE_DIR"
scp Dockerfile.demo nginx.demo.conf demo:$REMOTE_DIR/
ssh demo << EOF
cd $REMOTE_DIR

cp /etc/letsencrypt/live/demo.fiscalismia.com/fullchain.pem $REMOTE_DIR/fullchain.pem
cp /etc/letsencrypt/live/demo.fiscalismia.com/privkey.pem $REMOTE_DIR/privkey.pem

podman build --no-cache \
  -f Dockerfile.demo \
  -t fiscalismia-demo:latest .

podman stop demo > /dev/null 2>&1
podman container rm demo > /dev/null 2>&1

podman run \
  --name demo \
  --detach \
  --rm \
  -p 443:443 \
  fiscalismia-demo:latest

podman logs --follow demo
EOF