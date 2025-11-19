#####################################################################################
# Fiscalismia-Loadbalancer HAProxy as central HTTPS Ingress for hcloud infrastructure
#####################################################################################

FROM haproxy:3.2.8-alpine

# Install additional tools for debugging and health checks
RUN apk add --no-cache \
    ca-certificates \
    curl \
    vim \
    && rm -rf /var/cache/apk/*

# Create necessary directories
RUN mkdir -p /usr/local/etc/haproxy

# Copy HAProxy configuration
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

# Validate configuration at build time
RUN haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg

# Expose ports
# 80  - HTTP - TODO Remove after Development concludes
# 443 - HTTPS (TLS Passthrough)
# 8404 - Stats page
EXPOSE 80 443 8404

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8404/stats || exit 1

# Run as non-root user (haproxy user already exists in official image)
USER haproxy

# Use exec form to ensure proper signal handling
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
