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

resolvectl status | head -12
resolvectl query quay.io

sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
cat /etc/resolv.conf

sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

sudo rm /etc/systemd/resolved.conf.d/dns.conf
sudo systemctl restart systemd-resolved
resolvectl query quay.io

echo "--- dns";       resolvectl query quay.io 2>&1 | head -3
echo "--- shell";     env | grep -i proxy
echo "--- docker";    docker info 2>/dev/null | grep -i proxy
echo "--- unit";      systemctl show docker --property=Environment
echo "--- direct";    curl -sS -I --max-time 10 --noproxy '*' https://quay.io/v2/ 2>&1 | head -2
echo "--- via proxy"; curl -sS -I --max-time 10 https://quay.io/v2/ 2>&1 | head -3
echo "--- pull";      docker pull quay.io/rockylinux/rockylinux:9 2>&1 | tail -3

sudo rm /etc/systemd/system/docker.service.d/http-proxy.conf
sudo systemctl daemon-reload
sudo systemctl restart docker
docker info | grep -i proxy

ping -c 2 8.8.8.8
curl -sS -I --max-time 10 https://www.google.com | head -1
curl -sS -I --max-time 10 http://archive.ubuntu.com | head -1

gsettings get org.gnome.system.proxy mode
gsettings get org.gnome.system.proxy.http host
gsettings get org.gnome.system.proxy.http port
grep -ri proxy /etc/environment /etc/apt/apt.conf.d/ 2>/dev/null
```
