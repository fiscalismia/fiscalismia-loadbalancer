## Fiscalismia HAProxy LoadBalancer

Enterprise-grade Layer-4 HAProxy load balancer for Fiscalismia infrastructure with Server Name Indication TLS extention based routing and TLS passthrough of binary TCP packets, with Proxy Protocol V2 headers prepended to the binary stream in order to preserve the original source ip, which can then be extracted by the endpoints via nginx reverse proxy configuration and exposed as HTTP forwarded and forwarded for http headers.

### Features

- **SNI-based routing**: Routes traffic based on TLS certificate's SNI
- **TLS Passthrough**: Encrypted traffic is sent through as binary TCP packets
- **Proxy Protocol V2**: Prepends proxy protocol headers to binary tcp stream to preserve client ip.
- **Health checks**: Automatic backend health monitoring
- **Metrics export**: Real-time metrics exported to Monitoring instance
- **Security hardened**: Minimal privileges, non-root service user, read-only filesystem

### Prerequisites

- Podman/Docker and Docker Compose installed
- LoadBalancer instance in Hetzner Public Network with TCP 443 Ingress allowed.
- Loadbalancer instance attached to Hetzner private networks via private network interface
- Domains pointing to the loadbalancer's public IP via Type A Record

### Architecture Overview

This HAProxy instance serves as the central ingress point for all Fiscalismia services, running on a Hetzner Cloud VPS with both public and private network interfaces:

- **Public Network**:
  - Receives incoming traffic from the internet on Port 443 only.
  - Production Firewall disallows all egress via the public network interface.
  - Traffic going out of the Loadbalancer is thus routed via the private network interface only.
  - For the loadbalancer to gain internet access for updating the container and OS, we route through a NAT-Gateway.

- **Private Networks**:
  - Demo Network (`172.20.0.0/23`)
    - Isolated Subnet for private instances (`172.20.0.0/30`)
    - Exposed Subnet for public instances (`172.20.1.0/29`)
  - Production Network (`172.24.0.0/23`)
    - Isolated Subnet for private instances (`172.24.0.0/28`)
    - Exposed Subnet for public instances (`172.24.1.0/29`)

### Loadbalancer Routing Map

| Domain | Target Service | Private IP | Description |
|--------|---------------|------------|-------------|
| `fiscalismia.com` | Frontend | `172.24.0.3` | Main Fiscalismia Frontend |
| `backend.fiscalismia.com` | Backend | `172.24.0.4` | Main REST API backend |
| `demo.fiscalismia.com` | Demo | `172.20.0.2` | Encapsulated Demo instance (frontend) |
| `backend.demo.fiscalismia.com` | Demo | `172.20.0.2` | Encapsulated Demo instance (backend) |
| `monitoring.fiscalismia.com` | Monitoring | `172.24.0.2` | Prometheus & Grafana dashboard |

### Remote testing

```bash
cd ~/git/fiscalismia-loadbalancer/
./scripts/deploy_latest_haproxy.sh
```

### Local Testing

```bash
cd ~/git/fiscalismia-loadbalancer
# Build and start the container
docker compose up -d
# Check logs
docker compose logs -f haproxy
docker compose logs --tail=100 haproxy
# Verify configuration
podman exec haproxy haproxy -c -f /usr/local/etc/haproxy.cfg
```

```bash
# NET_BIND_SERVICE allows non-priviledged service user in container to bind to ports below 1024
# also requires to adjust sysctl config on linux host since kernels prevent this behavior
# this command sets it ephemerally for the session and is lost after reboot.
# the persisted config change is added as cloud-config.loadbalancer.yml in the infrastructure repo
podman build --no-cache -f Dockerfile -t fiscalismia-loadbalancer:latest .
podman container rm haproxy || true
sudo sysctl net.ipv4.ip_unprivileged_port_start=80
podman run  --name haproxy --rm \
  --cap-add=NET_BIND_SERVICE \
  --network host \
  --env-file .env \
  -v "$HOME/git/fiscalismia-loadbalancer/haproxy.cfg:/usr/local/etc/haproxy.cfg:ro,z" \
  fiscalismia-loadbalancer:latest
```

### Stats Dashboard (during development only)

Access real-time HAProxy statistics (replaced later with Monitoring instance):

```
URL: http://<loadbalancer-ip>:8404/stats
Username: save in .env
Password: save in .env
```

### Health Checks

HAProxy automatically monitors backend health:

- **Interval**: Every 10 seconds
- **Failure threshold**: 3 consecutive failures
- **Recovery threshold**: 2 consecutive successes

## Additional Resources

- [HAProxy Introduction Guide](https://www.haproxy.com/blog/the-four-essential-sections-of-an-haproxy-configuration)
- [HAProxy Configuration Manual](https://www.haproxy.com/documentation/haproxy-configuration-manual/latest/)
- [HAProxy Client IP Preservation](https://www.haproxy.com/documentation/haproxy-configuration-tutorials/proxying-essentials/client-ip-preservation/)
- [HAProxy Client Side Encryption](https://www.haproxy.com/documentation/haproxy-configuration-tutorials/security/ssl-tls/client-side-encryption/)
- [HAProxy Server Side Encryption](https://www.haproxy.com/documentation/haproxy-configuration-tutorials/security/ssl-tls/server-side-encryption/)

## License

See [LICENSE](LICENSE) file for details.
