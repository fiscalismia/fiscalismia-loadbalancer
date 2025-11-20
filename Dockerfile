#####################################################################################
# Fiscalismia-Loadbalancer HAProxy as central HTTPS Ingress for hcloud infrastructure
#####################################################################################

FROM docker.io/library/haproxy:3.2.8-alpine

# Copy HAProxy configuration
COPY haproxy.cfg /usr/local/etc/haproxy.cfg

# Validate configuration at build time
RUN haproxy -c -f /usr/local/etc/haproxy.cfg

# Expose ports - this is a purely cosmetic setting. It is applied in docker compose.
# 80  - HTTP - TODO Remove after Development concludes
# 443 - HTTPS (TLS Passthrough)
# 8404 - Stats page - TODO Remove after Development concludes
EXPOSE 80 443 8404

# Run as non-root user after binding to ports (haproxy user already exists in official image)
USER haproxy

# Use exec form to ensure proper signal handling
CMD ["haproxy", "-f", "/usr/local/etc/haproxy.cfg"]
