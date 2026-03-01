#####################################################################################
# Fiscalismia-Loadbalancer HAProxy as central HTTPS Ingress for hcloud infrastructure
#####################################################################################

FROM docker.io/library/haproxy:3.2.13-alpine

# 1. Switch to root to have permission to create directories
USER root

# 2. Create the directory and ensure haproxy user owns it
RUN mkdir -p /usr/local/etc/haproxy/errorfiles/
RUN chown -R haproxy:haproxy /usr/local/etc/haproxy/

WORKDIR /usr/local/etc/haproxy/

COPY haproxy.cfg /usr/local/etc/haproxy.cfg
COPY 503.http /usr/local/etc/haproxy/errorfiles/503.http

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
