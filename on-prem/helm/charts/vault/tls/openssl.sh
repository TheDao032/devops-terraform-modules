openssl req -sha256 -x509 -newkey rsa:4096 -keyout tls.key -out tls.crt -days 3650 -nodes -config vault-csr.conf

sudo mv tls.crt /opt/vault/tls/
sudo mv tls.key /opt/vault/tls/
sudo chown vault:vault /opt/vault/tls/*
sudo chmod 600 /opt/vault/tls/*
