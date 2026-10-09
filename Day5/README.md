
## Install Azure CLI tool in Ubuntu
```
curl -fsSL 'https://azurecliprod.blob.core.windows.net/$root/deb_install.sh' | sudo bash
```

<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/865d526c-8034-440c-a873-a9d363df755d" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/42a78d1d-4f99-41b5-a661-2fd0235a8738" />


## Lab - Login to Azure portal from command-line
```
az login --tenant <TENANT_ID> --use-device-code
az account set --subscription <SUBSCRIPTION_ID>
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/04dfc879-fe3e-4cd8-8bc4-67fc733e17ac" />

Check your Terraform version installed on your Cloud lab machine (Ubuntu)
```
pip install ansible pywinrm
terraform version                      # needs 1.4 or newer
```

Create ansible vault
```
echo 'root@123' > .vault_pass && chmod 600 .vault_pass
cd ansible
cp group_vars/all/vault.yml.example group_vars/all/vault.yml
vi group_vars/all/vault.yml
```

Add the below details
<pre>
vault_azure_subscription_id: "<SUBSCRIPTION_ID>"
vault_azure_tenant_id: "<TENANT_ID>"
vault_windows_admin_password: "Choose-12-Or-More-Chars-1!"  
</pre>

Encrypt your vault file
```
ansible-vault encrypt group_vars/all/vault.yml
```

Run Terraform
```
./run.sh plan
./run.sh
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/25d0a982-ca9e-4e4b-be17-91857fb83c16" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/55393ef3-c5dc-4349-9b94-50ccc3ce62e6" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/4bc9e7d4-bffa-43a5-b85d-32ebd0995ed9" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/8c95bcb0-2b3e-44f8-98f0-9068c0b91e7e" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/8c6ecd73-e499-4bdd-964f-b209835b2507" />

<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/b8e4afa8-c849-49b7-bdb1-49b5753b69ad" />

<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/087e84c4-f3e3-45d0-885f-4b1394f6e7c2" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/5f4a810b-8c7c-427f-898d-351dc00f48d4" />

## Lab - Install nginx in Ubuntu, RHEL and Windows Azure vms
Install the required tools if they are not there
```
cd ~/ansible-oct-2026
git pull

cd Day5/azure

# Let's use ansible in virtual environment
python3 -m venv ~/ansible-venv
source ~/ansible-venv/bin/activate

ansible-galaxy collection install -r ansible/requirements.yml

pip install ansible pywinrm
hash -r
ansible-galaxy collection install azure.azcollection

pip install -r ~/ansible-venv/lib/python3.14/site-packages/ansible_collections/azure/azcollection/requirements.txt
```

Check and update your resource group name
```
grep -A1 include_vm_resource_groups ansible/inventory.azure_rm.yml
grep existing_resource_group_name terraform.tfvars


```

Run the playbook
```

sed -i 's/your-resource-group/RG-CUST-385-U14/' ansible/inventory.azure_rm.yml
grep -A1 include_vm_resource_groups ansible/inventory.azure_rm.yml


./azure-env.sh bash -c 'az login --service-principal -u "$AZURE_CLIENT_ID" -p "$AZURE_SECRET" --tenant "$AZURE_TENANT" -o none && az vm list -g RG-CUST-385-U14 -d -o table'

./azure-env.sh ansible-inventory -i inventory.azure_rm.yml --graph

./azure-env.sh ansible-playbook -i inventory.azure_rm.yml install-nginx-playbook.yml
```


## Lab - VyOS Network Lab
```
sudo cp ~/Downloads/vyos.iso /var/lib/libvirt/images/vyos.iso

sudo virt-install --name vyos-vm --memory 1024 --vcpus 1 \
  --disk size=4 --cdrom /var/lib/libvirt/images/vyos.iso \
  --os-variant debian12 --network network=default --graphics vnc
```

Open the console with virt-viewer, install with defaults, configure user and password to vyos, reboot.

Configure SSH
```
configure
set interfaces ethernet eth0 address dhpc
set service ssh port 22
commit
save
exit
show interfaces
```

Install the collections
```
ansible-galaxy collection install vyos.vyos ansible.netcommon
pip install ansible-pylibssh
```

Create inventory.ini
```
[routers]
vyos-vm ansible_host=192.168.122.50

[routers:vars]
ansible_connection=ansible.netcommon.network_cli
ansible_network_os=vyos.vyos.vyos
ansible_user=vyos
ansible_password=vyos
ansible_host_key_checking=false
```

Playbook
<pre>
- name: Automate VyOS routers
  hosts: routers
  tasks:
  - name: Collect device facts
    vyos.vyos.vyos_facts:
      gather_subset: min
  - name: Print VyOS version
    debug: var=ansbile_net_version

  - name: Configure hostname, dummy interface and static route
    vyos.vyos.vyos_config:
      lines:
      - set system host-name {{ inventory_hostname }}
      - set interfaces dummy dum0 address 10.10.10.1/32
      - set interfaces dummy dum0 description ANSIBLE-LAB
      - set protocols static route 192.168.100.0/24 blackhole
      save: true

  - name: Verify the resule
    vyos.vyos.vyos_command:
      commands:
      - show interfaces
      - show ip route static
    register result
  - name: Print verification output
    debug: var=result.stdout_lines
</pre>


Run it
```
ansible-playbook -i inventory.ini vyos.yml
```
