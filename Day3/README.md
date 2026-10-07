# Day 3

## Lab - Installing Ansible Tower opensource variant (AWX)
Install the Kubernetes cluster
```
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER: ~/.kube/config
chmod 600 ~/.kube/config

ansible-playbook -i localhost, -c local -K install-awx.yml \
  -e kubeconfig=$HOME/.kube/config \
  -e ansible_python_interpreter=/usr/bin/python3
```

Install the AWX
```
mkdir -p k8s

cat > k8s/kustomization.yaml <<'EOF'
---
# AWX Operator 2.19.1, the release that installs AWX 24.6.1
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: awx

resources:
  - github.com/ansible/awx-operator/config/default?ref=2.19.1
  - awx-admin-secret.yaml
  - awx.yaml

images:
  - name: quay.io/ansible/awx-operator
    newTag: 2.19.1
EOF

cat > k8s/awx.yaml <<'EOF'
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
spec:
  admin_user: admin
  admin_password_secret: awx-admin-password
  # Reach the web UI on port 30080 of the node
  service_type: nodeport
  nodeport_port: 30080
  # Small lab sizes; the operator's defaults assume a bigger cluster
  web_resource_requirements:
    requests: {cpu: 250m, memory: 512Mi}
  task_resource_requirements:
    requests: {cpu: 250m, memory: 512Mi}
  postgres_storage_requirements:
    requests: {storage: 8Gi}
EOF

cat > k8s/awx-admin-secret.yaml <<'EOF'
---
# Lab only: in a real setup, create this Secret from a vault, not from Git
apiVersion: v1
kind: Secret
metadata:
  name: awx-admin-password
type: Opaque
stringData:
  password: Change-Me-Lab-2026
EOF

cat > k8s/awx-backup.yaml <<'EOF'
---
# Back up the AWX database and secrets to a persistent volume
apiVersion: awx.ansible.com/v1beta1
kind: AWXBackup
metadata:
  name: awx-backup-lab
  namespace: awx
spec:
  deployment_name: awx
  backup_storage_requirements: 5Gi
EOF

cat > k8s/awx-restore.yaml <<'EOF'
---
# Restore into a new AWX named awx-restored from a named backup
apiVersion: awx.ansible.com/v1beta1
kind: AWXRestore
metadata:
  name: awx-restore-lab
  namespace: awx
spec:
  deployment_name: awx-restored
  backup_name: awx-backup-lab
EOF

ls -1 k8s
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/5527bf68-17b3-47eb-b4d2-4320b7edd4f1" />
