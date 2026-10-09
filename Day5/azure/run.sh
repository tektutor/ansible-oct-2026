#!/usr/bin/env bash
# Decrypts the Azure credentials from Ansible Vault, signs in to Azure,
# then runs Terraform.
#
#   ./run.sh              -> terraform apply
#   ./run.sh plan         -> terraform plan
#   ./run.sh destroy      -> terraform destroy
#
# Auth mode is chosen from the vault content:
#   client id + client secret present -> service principal
#   otherwise                         -> user account through Azure CLI
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_FILE="$ROOT/ansible/group_vars/all/vault.yml"
VAULT_PASS="$ROOT/.vault_pass"

die() { echo "ERROR: $*" >&2; exit 1; }

for tool in terraform ansible-vault ansible-playbook ansible-galaxy python3; do
  command -v "$tool" >/dev/null || die "$tool is not installed"
done
[ -f "$VAULT_PASS" ] || die "create $VAULT_PASS with your vault password (chmod 600)"
[ -f "$VAULT_FILE" ] || die "$VAULT_FILE not found. Copy vault.yml.example and encrypt it"
head -n 1 "$VAULT_FILE" | grep -q '^\$ANSIBLE_VAULT' ||
  die "$VAULT_FILE is not encrypted. Run: ansible-vault encrypt $VAULT_FILE"

# ansible.cfg in ansible/ points ansible-vault at ../.vault_pass
assignments="$(cd "$ROOT/ansible" && ansible-vault view group_vars/all/vault.yml | python3 -c '
import shlex, sys

keys = ["azure_username", "azure_password", "azure_client_id",
        "azure_client_secret", "azure_subscription_id", "azure_tenant_id",
        "windows_admin_password"]
found = {}
for line in sys.stdin:
    line = line.strip()
    if not line or line.startswith("#") or ":" not in line:
        continue
    key, value = line.split(":", 1)
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"\x27":
        value = value[1:-1]
    found[key.strip()] = value
for key in keys:
    print("V_%s=%s" % (key, shlex.quote(found.get("vault_" + key, ""))))
')"
eval "$assignments"
unset assignments

[ -n "$V_windows_admin_password" ] || die "vault_windows_admin_password is empty in vault.yml"
export TF_VAR_windows_admin_password="$V_windows_admin_password"

if [ -n "$V_azure_client_id" ] && [ -n "$V_azure_client_secret" ]; then
  echo "Azure auth: service principal"
  [ -n "$V_azure_subscription_id" ] || die "vault_azure_subscription_id is required with a service principal"
  [ -n "$V_azure_tenant_id" ] || die "vault_azure_tenant_id is required with a service principal"
  export ARM_CLIENT_ID="$V_azure_client_id"
  export ARM_CLIENT_SECRET="$V_azure_client_secret"
  export ARM_SUBSCRIPTION_ID="$V_azure_subscription_id"
  export ARM_TENANT_ID="$V_azure_tenant_id"
else
  echo "Azure auth: user account through Azure CLI"
  command -v az >/dev/null || die "Azure CLI (az) is not installed"
  tenant_args=()
  [ -n "$V_azure_tenant_id" ] && tenant_args=(--tenant "$V_azure_tenant_id")

  if ! az account show --output none 2>/dev/null; then
    logged_in=no
    if [ -n "$V_azure_username" ] && [ -n "$V_azure_password" ]; then
      if az login --username "$V_azure_username" --password "$V_azure_password" \
            "${tenant_args[@]}" --output none; then
        logged_in=yes
      else
        echo "Password sign-in failed. Common causes: the temporary password is" >&2
        echo "not changed yet, or the account requires MFA. Trying device code." >&2
      fi
    fi
    if [ "$logged_in" = no ]; then
      az login --use-device-code "${tenant_args[@]}" --output none
    fi
  fi

  [ -n "$V_azure_subscription_id" ] && az account set --subscription "$V_azure_subscription_id"
  ARM_SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
  ARM_TENANT_ID="$(az account show --query tenantId --output tsv)"
  export ARM_SUBSCRIPTION_ID ARM_TENANT_ID
  echo "Subscription: $(az account show --query name --output tsv) ($ARM_SUBSCRIPTION_ID)"
fi
unset V_azure_password V_azure_client_secret V_windows_admin_password

cd "$ROOT"
action="${1:-apply}"
if [ "$action" = "apply" ]; then
  ansible-galaxy collection install -r ansible/requirements.yml
fi
terraform init -input=false
terraform "${@:-apply}"
