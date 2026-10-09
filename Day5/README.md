
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
