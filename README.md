## Fiscalismia HAProxy LoadBalancer

Enterprise-grade HAProxy load balancer for Fiscalismia infrastructure with host-based routing and TLS passthrough capabilities to force mutual TLS (mTLS) for instances in the private network

### Architecture Overview

This HAProxy instance serves as the central ingress point for all Fiscalismia services, running on a Hetzner Cloud VPS with both public and private network interfaces:

- **Public Network**: Receives incoming traffic from the internet. Production Firewall only allows Port 443 Ingress.
- **Private Networks**:
  - Demo Network (`172.20.0.0/23`)
  - Production Network (`172.24.0.0/23`)

### Routing Map

| Domain | Target Service | Private IP | Description |
|--------|---------------|------------|-------------|
| `fiscalismia.com` | Frontend | `172.24.0.3` | Main Fiscalismia Frontend |
| `backend.fiscalismia.com` | Backend | `172.24.0.4` | Main REST API backend |
| `demo.fiscalismia.com` | Demo | `172.20.0.2` | Encapsulated Demo instance (frontend) |
| `backend.demo.fiscalismia.com` | Demo | `172.20.0.2` | Encapsulated Demo instance (backend) |
| `monitoring.fiscalismia.com` | Monitoring | `172.24.0.2` | Prometheus & Grafana dashboard |

## Features

- **Host-based routing**: Routes traffic based on domain name via Route 53 Type A Record
- **TLS Passthrough**: Encrypted traffic forwarded without termination
- **Health checks**: Automatic backend health monitoring
- **Metrics export**: Real-time metrics exported to Monitoring instance
- **Security hardened**: Minimal privileges, non-root service user, read-only filesystem

### Prerequisites

- Podman/Docker and Docker Compose installed
- Access to Hetzner VPS with configured private networks
- Domains pointing to the loadbalancer's public IP

### Local Testing

```bash
# Clone the repository
cd fiscalismia-loadbalancer

# Build and start the container
docker-compose up -d

# Check logs
docker-compose logs -f haproxy

# Verify configuration
docker exec fiscalismia-loadbalancer haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg
```

### Stats Dashboard (during development only)

Access real-time HAProxy statistics (replaced later with Monitoring instance):

```
URL: http://<loadbalancer-ip>:8404/stats
Username: admin
Password: changeme123  # TODO: Replace with .env var or secret from pipeline
```

### Health Checks

HAProxy automatically monitors backend health:

- **Interval**: Every 10 seconds
- **Failure threshold**: 3 consecutive failures
- **Recovery threshold**: 2 consecutive successes
- **Health endpoint**: `GET /hc` (ensure backends implement this)

### Logs

View HAProxy logs:

```bash
# Real-time logs
docker-compose logs -f haproxy

# Last 100 lines
docker-compose logs --tail=100 haproxy
```

### Local Testing Without Backend Services

Use `docker run` to simulate backends:

```bash
# Terminal 1: Simulate frontend
docker run -d --name test-frontend -p 8081:80 nginx

# Terminal 2: Simulate backend
docker run -d --name test-backend -p 8082:80 nginx

# Update haproxy.cfg to point to localhost:8081 and localhost:8082
# Restart HAProxy and test with curl
curl -H "Host: fiscalismia.com" http://localhost
```

### Testing Host-Based Routing

```bash
# Test each domain
curl -H "Host: fiscalismia.com" http://localhost
curl -H "Host: backend.fiscalismia.com" http://localhost
curl -H "Host: demo.fiscalismia.com" http://localhost
curl -H "Host: backend.demo.fiscalismia.com" http://localhost
curl -H "Host: monitoring.fiscalismia.com" http://localhost
```

## Additional Resources

- [HAProxy Best Practices](https://www.haproxy.com/blog/haproxy-best-practice-guide)

## License

See [LICENSE](LICENSE) file for details.
