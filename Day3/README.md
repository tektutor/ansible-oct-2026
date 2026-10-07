# Day 3

## Lab - Installing Ansible Tower opensource variant (AWX)
Check if all the required files are present
```
cd ~/ansible-oct-2026
git pull
cd Day3/cd awx-lab
ls -1 . k8s
```

Install the tools
```
sudo apt update
sudo apt install -y curl unzip git python3-venv
```

Check the tools
```
# Let's use ansible in virtual environment
python3 -m venv ~/ansible-venv
source ~/ansible-venv/bin/activate
pip install "ansible-core>=2.21,<2.22" jsonschema
ansible --version

# Install Kubernetes collections
ansible-galaxy collection install kubernetes.core
ansible-galaxy collection list kubernetes.core

# Install kustomize
url=https://github.com/kubernetes-sigs/kustomize/releases/download
curl -sL "$url/kustomize%2Fv5.8.1/kustomize_v5.8.1_linux_amd64.tar.gz" \
  | sudo tar -xz -C /usr/local/bin kustomize
kustomize version

# Open up required ports on firewall
sudo ufw allow from 10.42.0.0/16
sudo ufw allow from 10.43.0.0/16
sudo ufw allow 30080/tcp
sudo ufw allow 30081/tcp

# Check everything
git --version
kustomize version
python3 -c "import jsonschema, yaml; print('python libraries ok')"
ansible --version | sed -n 1p
ansible-galaxy collection list kubernetes.core | tail -2
free -g | sed -n 2p
```

Render and check the files
```
cd ~/ansible-oct-2026
cd Day3/cd awx-lab

kustomize build k8s > /tmp/awx-rendered.yaml
grep -c '^kind:' /tmp/awx-rendered.yaml
python3 validate_crs.py /tmp/awx-rendered.yaml \
  k8s/awx.yaml k8s/awx-backup.yaml k8s/awx-restore.yaml
```

Install K3S cluster and setup AWX
```
time ansible-playbook -i inventory.yml -K install-awx.yml \
  -e k3s_kubeconfig_mode=0644
```

Check the pods
```
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl -n awx get pods
```

Backup
```
kubectl apply -f k8s/awx-backup.yaml
sleep 180
kubectl -n awx get awxbackup awx-backup-lab -o yaml | sed -n '/^status:/,$p'
```

Restore
```
kubectl apply -f k8s/awx-restore.yaml
sleep 300
kubectl -n awx get pods
kubectl -n awx get services
```

Accessing AWX Dashboard on the web browser
```
http://localhost:30080
# or Find the IP of the AWX machine to access from another machine
sudo ufw allow 30080/tcp
hostname -I | awk '{print $1}'
http://192.168.200.46:30080
```

Find the password
```
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl -n awx get secret awx-admin-password \
  -o jsonpath='{.data.password}' | base64 -d; echo
```

<img width="1920" height="1124" alt="image" src="https://github.com/user-attachments/assets/0ac5dca2-d985-4dcc-aadd-ed5bfb2e8efe" />
<img width="1920" height="1124" alt="image" src="https://github.com/user-attachments/assets/8c92ba4d-7ec0-45b2-baba-11d2fa03de3a" />
