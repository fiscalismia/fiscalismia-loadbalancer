#!/usr/bin/env bash

scp .env Dockerfile haproxy.cfg ./errorfiles/503.http root@loadbalancer:/usr/local/etc/haproxy/

ssh root@loadbalancer "
  cd /usr/local/etc/haproxy/

  podman build --no-cache \
    -f Dockerfile \
    -t fiscalismia-loadbalancer:latest .

  podman stop haproxy > /dev/null 2>&1
  podman container rm haproxy > /dev/null 2>&1

  # sudo sysctl net.ipv4.ip_unprivileged_port_start=80

  podman run \
    --name haproxy \
    --rm \
    --detach \
    --cap-add=NET_BIND_SERVICE \
    --network host \
    --env-file .env \
    -v "/usr/local/etc/haproxy/haproxy.cfg:/usr/local/etc/haproxy.cfg:ro,z" \
    fiscalismia-loadbalancer:latest

    podman logs --follow haproxy
"