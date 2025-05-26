#!/bin/bash

set -e

echo "[*] Starting automated SSL setup for Splunk with custom CA..."

# Configuration
CERT_DIR="/opt/splunk/certs"
SPLUNK_AUTH_DIR="/opt/splunk/etc/auth"
NIFI_CERT_DIR="/etc/nifi/certs"
HOST_IP=$(hostname -I | awk '{print $1}')
FQDN=$(hostname -f)

mkdir -p "$CERT_DIR"
cd "$CERT_DIR"

echo "[*] Generating Root CA key..."
openssl genrsa -out rootCA.key 2048

echo "[*] Generating Root CA certificate..."
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.pem -subj "/C=US/ST=State/L=City/O=Org/OU=Unit/CN=CustomCA"

echo "[*] Generating server key..."
openssl genrsa -out server.key 2048

echo "[*] Generating CSR..."
openssl req -new -key server.key -out server.csr -subj "/C=US/ST=State/L=City/O=Org/OU=Splunk/CN=${FQDN}"

echo "[*] Creating SAN config file..."
cat > server.ext <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${FQDN}
IP.1 = ${HOST_IP}
EOF

echo "[*] Signing server certificate..."
openssl x509 -req -in server.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial \
-out server.crt -days 500 -sha256 -extfile server.ext

echo "[*] Verifying certificates..."
openssl x509 -in rootCA.pem -text -noout > /dev/null
openssl x509 -in server.crt -text -noout | grep -A5 "Subject Alternative Name"

echo "[*] Creating PEM file for Splunk..."
cat server.key server.crt rootCA.pem > server.pem

echo "[*] Copying certificates to Splunk auth directory..."
cp server.pem "${SPLUNK_AUTH_DIR}/server.pem"
cp rootCA.pem "${SPLUNK_AUTH_DIR}/cacert.pem"

echo "[*] Setting up truststore for NiFi..."
keytool -importcert -noprompt -alias splunk-ca -file rootCA.pem \
-keystore splunk-truststore.jks -storepass changeit -storetype JKS

echo "[*] Moving truststore to NiFi certs folder..."
sudo mkdir -p "${NIFI_CERT_DIR}"
sudo mv splunk-truststore.jks "${NIFI_CERT_DIR}/"
sudo chown nifi:nifi "${NIFI_CERT_DIR}/splunk-truststore.jks"
sudo chmod 640 "${NIFI_CERT_DIR}/splunk-truststore.jks"

echo "[✔] SSL setup completed successfully!"
