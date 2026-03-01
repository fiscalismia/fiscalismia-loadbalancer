#!/usr/bin/env bash

scp .env Dockerfile haproxy.cfg ./errorfiles/503.http root@loadbalancer:/usr/local/etc/haproxy/

# giving loadbalancer temporary internet access until reboot for pulling haproxy image
ssh loadbalancer << 'EOF'
timeout 2 curl -s ifconfig.me
exit_code=$?
# only execute if curl times out
if (( $exit_code > 0 )); then
  printf "\nSetting up ephemeral internet access via NAT GW\n"
  /root/scripts/nat_gw_ephemeral_public_egress.sh 172.24.1.3
else
  printf "\nInternet Access already setup. Continue.\n"
fi
EOF

ssh loadbalancer << EOF
  cd /usr/local/etc/haproxy/

  podman build --no-cache \
    -f Dockerfile \
    -t fiscalismia-loadbalancer:latest .

  podman stop haproxy > /dev/null 2>&1
  podman container rm haproxy > /dev/null 2>&1

  # sudo sysctl net.ipv4.ip_unprivileged_port_start=80

  # remove default rule pointing to nat gateway for internet access to reenable private network connections
  ip rule delete from all lookup nat_prod

  podman run \
    --name haproxy \
    --rm \
    --detach \
    --cap-add=NET_BIND_SERVICE \
    --network host \
    --env-file .env \
    -v "/usr/local/etc/haproxy/haproxy.cfg:/usr/local/etc/haproxy.cfg:ro,z" \
    fiscalismia-loadbalancer:latest

    # colorized logging
    /root/scripts/colorized-haproxy-logging.sh
EOF