# Day 5

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

