#!/usr/bin/env bash

REMOTE_DIR=/root/tls_listener

if [[ -z "$1" ]]; then
  echo "Error: Usage as follows:"
  echo "$0 <SSH_ALIAS>"
  exit 1
else
  echo "##### Starting TLS Lstnr (Port 443) on [$1] instance #####"
fi

# create unattended config file for certificate signing request
cat << 'EOF' > /tmp/unattended_csd.cnf
[ req ]
prompt = no
distinguished_name = dn_req

[ dn_req ]
countryName = DE
stateOrProvinceName = Berlin
localityName = Berlin
organizationName = Fiscalismia Test
organizationalUnitName = IT
commonName = fiscalismia.com
emailAddress = noreply@fiscalismia.com

[ v3_req ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = fiscalismia.com
DNS.2 = backend.fiscalismia.com
DNS.3 = fastapi.fiscalismia.com
DNS.4 = demo.fiscalismia.com
DNS.5 = backend.demo.fiscalismia.com
DNS.6 = fastapi.demo.fiscalismia.com
DNS.7 = monitoring.fiscalismia.com
EOF

# create remote directory
ssh $1 "mkdir -p $REMOTE_DIR"

# copy unattended config to target machine
scp /tmp/unattended_csd.cnf $1:$REMOTE_DIR/

# remove unattended config from source machine
rm -f /tmp/unattended_csd.cnf

# kill any existing listeners
ssh $1 << 'EOF'
netstat -ltnp | awk '/:443/ {split($7, a, "/"); print a[1]}' | grep -v '^-' | xargs -r kill
EOF

# create openssl certs
ssh $1 << EOF
cd $REMOTE_DIR

# generate private key with ECDSA algorithm
openssl genpkey -outform PEM -algorithm EC -pkeyopt ec_paramgen_curve:secp521r1 -out pkey.pem

# generate a certificate signing request for a CA or yourself leaving most info blank (= a single dot)
openssl req -new -config $REMOTE_DIR/unattended_csd.cnf -key pkey.pem -out ca_req.csr

# self sign tls certificate with SAN and CSR
openssl x509 -req -days 365 -in ca_req.csr -signkey pkey.pem -out self_signed.crt \
  -extfile $REMOTE_DIR/unattended_csd.cnf -extensions v3_req
EOF

# start openssl server in debugmode
ssh $1 "
# start tls listener able to decrypt incoming https requests
cd $REMOTE_DIR
openssl s_server \
  -accept 443 \
  -key pkey.pem \
  -cert self_signed.crt \
  -WWW \
  -state

  # -tlsextdebug \
  # -msg \
  # -debug \
"