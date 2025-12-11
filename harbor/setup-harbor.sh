
#!/bin/bash

# docker installation
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do  apt-get remove -y $pkg; done

# Add Docker's official GPG key:
apt-get update 
apt-get install ca-certificates curl -y
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
   tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
usermod -aG docker vagrant
newgrp docker


# Harbor installation
apt update
cd /opt

# Generate CA certificate private key
openssl genrsa -out ca.key 4096

# Generate CA certificat
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=CN/ST=Kathmandu/L=Kathmandu/O=example/OU=Personal/CN=Harbor Root CA" \
 -key ca.key \
 -out ca.crt


# Generate private key for domain
openssl genrsa -out harbor.registry.local.key 4096

# Generate a certificate signing request (CSR)
openssl req -sha512 -new \
    -subj "/C=CN/ST=Kathmandu/L=Kathmandu/O=example/OU=Personal/CN=harbor.registry.local" \
    -key harbor.registry.local.key \
    -out harbor.registry.local.csr

cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=harbor.registry.local
DNS.2=harbor.registry
DNS.3=harbor
EOF

openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in harbor.registry.local.csr \
    -out harbor.registry.local.crt

mkdir -p /data/cert
cp harbor.registry.local.crt /data/cert/
cp harbor.registry.local.key /data/cert/

openssl x509 -inform PEM -in harbor.registry.local.crt -out harbor.registry.local.cert

mkdir -p /etc/docker/certs.d/harbor.registry.local
cp harbor.registry.local.cert /etc/docker/certs.d/harbor.registry.local/
cp harbor.registry.local.key /etc/docker/certs.d/harbor.registry.local/
cp ca.crt /etc/docker/certs.d/harbor.registry.local/

systemctl restart docker

cd ~
systemctl restart docker
wget https://github.com/goharbor/harbor/releases/download/v2.6.1/harbor-offline-installer-v2.6.1.tgz

tar xzvf harbor-offline-installer-v2.6.1.tgz
cd harbor
cp harbor.yml.tmpl harbor.yml

# Update hostname
sed -i "s/^hostname:.*/hostname: harbor.registry.local/" "./harbor.yml"

# Update certificate path
sed -i "s|^  certificate:.*|  certificate: /data/cert/harbor.registry.local.crt|" "./harbor.yml"

# Update private_key path
sed -i "s|^  private_key:.*|  private_key: /data/cert/harbor.registry.local.key|" "./harbor.yml"

./install.sh --with-trivy

