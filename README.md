# ansible-oct-2026

## Troubleshooting DNS issues on the Ubuntu VM
```
curl -sI --max-time 10 https://www.google.com | head -1
curl -sI --max-time 10 https://registry-1.docker.io/v2/ | head -1
env | grep -i proxy

docker pull mirror.gcr.io/library/ubuntu:24.04

echo '{ "registry-mirrors": ["https://mirror.gcr.io"] }' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
docker pull ubuntu:24.04

sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null <<'EOF'
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:8080"
Environment="HTTPS_PROXY=http://proxy.example.com:8080"
Environment="NO_PROXY=localhost,127.0.0.1"
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```
