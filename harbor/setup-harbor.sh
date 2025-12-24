#!/bin/bash
set -e

echo "===== Docker Cleanup ====="
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  apt-get remove -y $pkg || true
done

echo "===== Docker Installation ====="
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release wget tar openssl

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
> /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker

usermod -aG docker vagrant || true

echo "===== Harbor Certificate Setup ====="
cd /opt

openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -sha512 -days 3650 \
  -subj "/C=NP/ST=Bagmati/L=Kathmandu/O=Example/OU=IT/CN=Harbor Root CA" \
  -key ca.key -out ca.crt

openssl genrsa -out harbor.registry.local.key 4096
openssl req -sha512 -new \
  -subj "/C=NP/ST=Bagmati/L=Kathmandu/O=Example/OU=IT/CN=harbor.registry.local" \
  -key harbor.registry.local.key \
  -out harbor.registry.local.csr

cat > v3.ext <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature, keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=@alt_names

[alt_names]
DNS.1=harbor.registry.local
EOF

openssl x509 -req -sha512 -days 3650 \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -in harbor.registry.local.csr \
  -out harbor.registry.local.crt \
  -extfile v3.ext

mkdir -p /data/cert
cp harbor.registry.local.crt harbor.registry.local.key /data/cert/

openssl x509 -inform PEM -in harbor.registry.local.crt \
  -out /data/cert/harbor.registry.local.cert

mkdir -p /etc/docker/certs.d/harbor.registry.local:443
cp /data/cert/harbor.registry.local.cert /etc/docker/certs.d/harbor.registry.local:443/
cp harbor.registry.local.key /etc/docker/certs.d/harbor.registry.local:443/
cp ca.crt /etc/docker/certs.d/harbor.registry.local:443/

systemctl restart docker

echo "===== Harbor Installation ====="
cd /opt
wget https://github.com/goharbor/harbor/releases/download/v2.10.0/harbor-offline-installer-v2.10.0.tgz

tar -xvf harbor-offline-installer-v2.10.0.tgz
cd harbor

cp harbor.yml.tmpl harbor.yml

sed -i "s/^hostname:.*/hostname: harbor.registry.local/" harbor.yml
sed -i "s|^  certificate:.*|  certificate: /data/cert/harbor.registry.local.crt|" harbor.yml
sed -i "s|^  private_key:.*|  private_key: /data/cert/harbor.registry.local.key|" harbor.yml

./install.sh --with-trivy
