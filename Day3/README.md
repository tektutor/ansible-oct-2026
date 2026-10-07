# Day 3

## Lab - Installing Ansible Tower opensource variant (AWX)
Check if all the required files are present
```
cd ~/ansible-oct-2026
git pull
cd Day3/awx-lab
ls -1 . k8s
```

Install the tools
```
sudo apt update
sudo apt install -y curl unzip git python3-venv
sudo apt install -y python3-pip python3-jsonschema python3-yaml
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
cd Day3/awx-lab

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
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/2e6254af-5be7-4efa-a3b8-836fc26877bf" />

<img width="1920" height="1124" alt="image" src="https://github.com/user-attachments/assets/8c92ba4d-7ec0-45b2-baba-11d2fa03de3a" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/fa844ab6-7e6a-4d1e-bd46-57dba978a81e" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/10709d01-84fc-4707-a177-821cfa3be340" />

In case, you wish to uninstall ( not required )
```
sudo /usr/local/bin/k3s-uninstall.sh
sudo rm -rf /opt/awx
sudo rm -f /usr/local/bin/k3s-install.sh
grep -c "127.0.0.1:6443" ~/.kube/config
rm ~/.kube/config
unset KUBECONFIG
sudo ufw delete allow from 10.42.0.0/16
sudo ufw delete allow from 10.43.0.0/16
sudo ufw delete allow 30080/tcp
sudo ufw delete allow 30081/tcp

# Optional
sudo rm -f /usr/local/bin/kustomize
sudo apt remove -y python3-kubernetes
rm -rf ~/ansible-venv

# Check everything is gone
systemctl status k3s 2>&1 | head -2
ls /var/lib/rancher /etc/rancher /opt/awx 2>&1
sudo ss -ltnp | grep -E ":(6443|30080|30081)\b"
ip link | grep -E "cni0|flannel"
```

## Lab - Configuring Windows 2022 Server to ensure ansible can manage it
On Windows 2022 Server Powershell command prompt
```
# ---------- Settings (lab use only) ----------
$userName = "ansible"
$plain    = "WinLab2026Pass"     # must not contain the username
$secure   = ConvertTo-SecureString $plain -AsPlainText -Force

# 1. Create the user, or reset the password if the user exists
if (Get-LocalUser -Name $userName -ErrorAction SilentlyContinue) {
    Set-LocalUser -Name $userName -Password $secure -PasswordNeverExpires $true
    Enable-LocalUser -Name $userName
} else {
    New-LocalUser -Name $userName -Password $secure `
        -PasswordNeverExpires -AccountNeverExpires | Out-Null
}

# 2. Add the user to Administrators
if (-not (Get-LocalGroupMember -Group "Administrators" -Member $userName -ErrorAction SilentlyContinue)) {
    Add-LocalGroupMember -Group "Administrators" -Member $userName
}

# 3. Give remote local-account logins full admin rights
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System `
    -Name LocalAccountTokenFilterPolicy -Value 1 -PropertyType DWord -Force | Out-Null

# 4. Enable PowerShell remoting
Enable-PSRemoting -Force -SkipNetworkProfileCheck | Out-Null

# 5. Create the HTTPS listener if it does not exist
$httpsListener = Get-ChildItem WSMan:\localhost\Listener |
    Where-Object { $_.Keys -contains "Transport=HTTPS" }

if (-not $httpsListener) {
    $cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME `
        -CertStoreLocation Cert:\LocalMachine\My
    New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * `
        -CertificateThumbPrint $cert.Thumbprint -Force | Out-Null
}

# 6. Open port 5986 in the firewall
if (-not (Get-NetFirewallRule -DisplayName "WinRM HTTPS" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "WinRM HTTPS" -Direction Inbound `
        -Protocol TCP -LocalPort 5986 -Action Allow | Out-Null
}

# 7. Restart WinRM
Restart-Service WinRM

# 8. Show the state
"--- User ---"
Get-LocalUser -Name $userName | Select-Object Name, Enabled | Format-Table -AutoSize
"--- Administrators ---"
Get-LocalGroupMember -Group "Administrators" | Select-Object Name | Format-Table -AutoSize
"--- Token filter policy ---"
(Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System).LocalAccountTokenFilterPolicy
"--- Auth methods ---"
winrm get winrm/config/Service/Auth
"--- Listeners ---"
winrm enumerate winrm/config/Listener | Select-String "Transport|Port"

# 9. Test the login locally
"--- Local login test ---"
$cred = New-Object System.Management.Automation.PSCredential($userName, $secure)
Invoke-Command -ComputerName localhost -Credential $cred -ScriptBlock { whoami }
```

Enable WinRM and create HTTPS Listener
```
Enable-PSRemoting -Force

$cert = New-SelfSignedCertificate `
    -DnsName $env:COMPUTERNAME `
    -CertStoreLocation Cert:\LocalMachine\My

New-Item -Path WSMan:\localhost\Listener `
    -Transport HTTPS `
    -Address * `
    -CertificateThumbPrint $cert.Thumbprint `
    -Force

New-NetFirewallRule -DisplayName "WinRM HTTPS" `
    -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow
```

Verify the listeners are running 
```
winrm enumerate winrm/config/Listener
Test-NetConnection -ComputerName localhost -Port 5986
```


On your Ansible Control Node, run this to install WinRM and windows collections
```
python3 -m venv ~/ansible-venv
source ~/ansible-venv/bin/activate

pip install pywinrm
ansible-galaxy collection install ansible.windows community.windows
```

Create an inventory.ini
```
[windows]
win2022 ansible_host=192.168.122.247

[windows:vars]
ansible_user=ansible
ansible_password=WinLab2026Pass
ansible_connection=winrm
ansible_port=5986
ansible_winrm_scheme=https
ansible_winrm_transport=ntlm
ansible_winrm_server_cert_validation=ignore
```

Test the connection
```
ansible windows -i inventory.ini -m ansible.windows.win_ping
```
<img width="1920" height="1168" alt="image" src="https://github.com/user-attachments/assets/ea75d5ef-4a1c-44a1-9e00-5b58f20c2919" />

Run your first ansible playbook targeting your windows server
site.yml
```
---
- name: Configure Windows Server 2022
  hosts: windows
  gather_facts: true
  tasks:
    - name: Install IIS
      ansible.windows.win_feature:
        name: Web-Server
        state: present
        include_management_tools: true

    - name: Ensure IIS service runs
      ansible.windows.win_service:
        name: W3SVC
        state: started
        start_mode: auto
```

Run it from Ubuntu terminal
```
ansible-playbook -i inventory.ini site.yml
curl -I http://192.168.122.247
```
<img width="1920" height="1168" alt="image" src="https://github.com/user-attachments/assets/d1cbf11c-abc9-4629-b7e5-ed2a618f50e3" />

Troubleshooting Common failures
<pre>
- Connection timeout: a network firewall or cloud security group blocks port 5986.
- "Access is denied" with a local account: remote UAC filtering strips the admin token. 
</pre>

Fix it with - Run this on your Windows 2022 Server Powershell prompt
```
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System `
    -Name LocalAccountTokenFilterPolicy -Value 1 -PropertyType DWord -Force
```


## Info - What are the different ways Windows Ansible Nodes can be authenticated 

WinRM authentication options
<pre>
- Basic
- Certificate
- NTLM
- Kerberos
- CredSSP
</pre>

Basic authentication
<pre>
- Sends the username and password base64-encoded, so use it only over HTTPS (port 5986) and only in a lab
- Windows disables it by default
</pre>

So, we need to enable it on the Windows Powershell prompt
```
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
```

In your ansible inventory, add this line
```
ansible_winrm_transport=basic
```

Certificate
<pre>
- Works like SSH key pairs
- you map a client certificate to a local Windows account, and no password travels over the network
- it requires HTTPS
- one caution for Server 2022
  - WinRM certificate authentication fails over TLS 1.3, which Server 2022 enables by default
  - you must force TLS 1.2 for the WinRM listener or choose another method
</pre>

Run this on your Windows Powershell prompt
```
Set-Item -Path WSMan:\localhost\Service\Auth\Certificate -Value $true
```

In your ansible inventory, add these lines
```
ansible_winrm_transport=certificate
ansible_winrm_cert_pem=/path/to/cert.pem
ansible_winrm_cert_key_pem=/path/to/key.pem
```

NTLM
<pre>
- Enabled by default on Windows and needs no extra setup
- It works for both local and domain accounts
- It is an older protocol with weaker security than Kerberos, and it cannot delegate credentials, 
  so tasks that reach a second server (a file share or SQL Server, for example) fail
</pre>

In the inventory
```
ansible_winrm_transport=ntlm
```

Kerberos
<pre>
- The recommended choice for domain-joined servers
- It gives you mutual authentication and supports delegation
- Your control node needs Kerberos libraries and a working /etc/krb5.conf, and ansible_host must be the server's FQDN, 
  because Kerberos fails against IP addresses
</pre>

Install this on your Ansible Control Node
```
sudo apt install krb5-user libkrb5-dev python3-dev gcc    # Debian/Ubuntu
pip install pywinrm[kerberos]
```

In the inventory
```
ansible_user=ansible@EXAMPLE.COM
ansible_winrm_transport=kerberos
ansible_winrm_kerberos_delegation=true    # only if you need double hop
```

CredSSP
<pre>
- Sends your credentials to the remote host, which then uses them to reach other servers
- It solves the double hop problem for both local and domain accounts
- The risk
  - if an attacker compromises that host, they can capture the credentials
  - Enable it only where you need it
</pre>

On Windows powershell prompt run this
```
Enable-WSManCredSSP -Role Server -Force
```

Install this on your ansible control node
```
pip install pywinrm[credssp]
```

To check, which authentication method your server supports/allows, run this on Windows Powershell prompt
```
winrm get winrm/config/Service/Auth
```
On your inventory
```
ansible_winrm_transport=credssp
```

## Lab - Using Certificate to authenticate windows configuration management

Generate the certificate and key on the Control node, 
```
USERNAME="ansible"

cat > openssl.conf << EOF
distinguished_name = req_distinguished_name

[req_distinguished_name]

[v3_req_client]
extendedKeyUsage = clientAuth
subjectAltName = otherName:1.3.6.1.4.1.311.20.2.3;UTF8:${USERNAME}@localhost
EOF

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -sha256 \
    -keyout cert_key.pem \
    -out cert.pem \
    -subj "/CN=${USERNAME}" \
    -config openssl.conf \
    -extensions v3_req_client

chmod 600 cert_key.pem
rm openssl.conf

# Confirm the extensions
openssl x509 -in cert.pem -noout -text | grep -A1 -E "Extended Key Usage|Subject Alternative Name"
```

On the Windows Server 2022 host
<pre>
- Copy cert.pem to the server (for example C:\temp\cert.pem), then run these in an elevated PowerShell session
- A self-signed certificate acts as its own issuer, so it goes into both Root and TrustedPeople
</pre>

Copy the Certificate
```
ansible windows -i inventory.ini -m ansible.windows.win_copy \
    -a 'src=cert.pem dest=C:\\temp\\cert.pem'
```

Powershell
```
$cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new("C:\temp\cert.pem")

foreach ($storeName in "Root", "TrustedPeople") {
    $store = Get-Item -Path "Cert:\LocalMachine\$storeName"
    $store.Open("ReadWrite")
    $store.Add($cert)
    $store.Dispose()
}

Set-Item -Path WSMan:\localhost\Service\Auth\Certificate -Value $true
```

Map the certificate to the local account
```
$credential = Get-Credential -UserName "ansible" -Message "Password for the local ansible account"

New-Item -Path WSMan:\localhost\ClientCertificate `
    -Subject "ansible@localhost" `
    -URI * `
    -Issuer $cert.Thumbprint `
    -Credential $credential `
    -Force
```

Disable TLS 1.3 for inbound connections
<pre>
- WinRM certificate authentication fails over TLS 1.3, and Server 2022 enables TLS 1.3 by default
- This registry change forces TLS 1.2
- It applies to every Schannel-based server service on the machine, including IIS, so check that this is acceptable before you apply it 
</pre>
```
$path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Server"
New-Item -Path $path -Force | Out-Null
New-ItemProperty -Path $path -Name Enabled -Value 0 -PropertyType DWord -Force
New-ItemProperty -Path $path -Name DisabledByDefault -Value 1 -PropertyType DWord -Force
Restart-Computer
```

On the Control node, update the inventory.ini
```
[windows]
win2022 ansible_host=192.168.1.50

[windows:vars]
ansible_connection=winrm
ansible_port=5986
ansible_winrm_scheme=https
ansible_winrm_transport=certificate
ansible_winrm_cert_pem=/home/jegan/certs/cert.pem
ansible_winrm_cert_key_pem=/home/jegan/certs/cert_key.pem
ansible_winrm_server_cert_validation=ignore
```


Test
```
ansible windows -i inventory.ini -m ansible.windows.win_ping
```

## Lab - Creating a sample ansible.cfg file
```
ansible-config init --disabled > ansible.cfg.example
```
