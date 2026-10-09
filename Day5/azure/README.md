# Terraform + Ansible on Azure (Ubuntu, RHEL, Windows)

Terraform creates three VMs in Azure and then runs an Ansible playbook on them.
The Azure service principal credentials and the Windows admin password live in
one Ansible Vault file. No secret appears in any `.tf` file.

## How the pieces connect

1. `run.sh` decrypts `ansible/group_vars/all/vault.yml`, signs in to Azure,
   and exports `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID` and
   `TF_VAR_windows_admin_password` for Terraform.
2. Terraform creates the network, the three VMs, and a WinRM HTTPS listener on
   the Windows VM.
3. Terraform writes `ansible/inventory.ini` and runs
   `ansible-playbook -i inventory.ini site.yml`.
4. Ansible reads the Windows password from the same vault file.

## Prerequisites on your control machine (Linux or WSL)

    terraform >= 1.4
    pip install ansible pywinrm
    ssh-keygen -t rsa -b 4096        # only if ~/.ssh/id_rsa does not exist

You also need the Azure CLI (`az`) when you sign in with a user account.

## Azure credentials: two options

**Option A: user account (username and password).** Sign in once at
https://portal.azure.com with the temporary password and set a new password.
Put the username and the new password in the vault. `run.sh` runs `az login`
with them, and Terraform uses that Azure CLI session. If the account requires
MFA, password sign-in fails and `run.sh` falls back to a device-code sign-in
that you complete in a browser.

**Option B: service principal.** Create it once and put the values in the vault:

    az ad sp create-for-rbac --name tf-ansible-sp --role Contributor \
        --scopes /subscriptions/<SUBSCRIPTION_ID>

`appId` is the client id, `password` is the client secret, `tenant` is the
tenant id. `run.sh` picks Option B when both client id and client secret are set.

## Setup

    echo 'your-vault-password' > .vault_pass && chmod 600 .vault_pass
    cd ansible
    cp group_vars/all/vault.yml.example group_vars/all/vault.yml
    vi group_vars/all/vault.yml                      # fill in your values
    ansible-vault encrypt group_vars/all/vault.yml
    cd ..

Edit the secrets later with `cd ansible && ansible-vault edit group_vars/all/vault.yml`.

## Lab or sandbox account with a pre-created resource group

Create `terraform.tfvars` next to `main.tf`:

    existing_resource_group_name = "your-resource-group"

Terraform then deploys into that group and uses its region. Add
`location = "eastus"` or `vm_size = "Standard_B2ms"` to the same file if your
lab restricts regions or sizes.

## Run

    ./run.sh            # terraform apply
    ./run.sh plan
    ./run.sh destroy

## What gets installed

- Ubuntu 22.04 and RHEL 9: nginx, git, tree, unzip
- Windows Server 2022: IIS, plus git, 7zip and Notepad++ through Chocolatey

Change the package lists in `ansible/site.yml`. Terraform reruns the playbook
when that file changes.

## Things to know

- The NSG allows ports 22, 5986 and 3389 only from the public IP of the machine
  that runs Terraform. Set `allowed_source_cidr` to override it.
- Terraform stores the Windows admin password in `terraform.tfstate`. Keep the
  state file private or use an encrypted remote backend.
- For a new resource group the default region is `centralindia`. The default size is `Standard_B2s`.
  Override them with `-var`, for example `./run.sh apply -var location=eastus`.
- Three B2s VMs with public IPs cost money while they run. Run
  `./run.sh destroy` when you finish.
