#!/usr/bin/env bash
# Exports the Azure credentials from the vault, then runs the given
# Ansible command inside ansible/.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ $# -gt 0 ] || { echo "Usage: $0 <ansible command> [args...]" >&2; exit 1; }
cd "$ROOT/ansible"

vault="$(ansible-vault view group_vars/all/vault.yml)"
get() {
  printf '%s\n' "$vault" | sed -n "s/^$1:[[:space:]]*//p" \
    | sed -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'\$/\1/" | head -n 1
}

AZURE_CLIENT_ID="$(get vault_azure_client_id)"
AZURE_SECRET="$(get vault_azure_client_secret)"
AZURE_SUBSCRIPTION_ID="$(get vault_azure_subscription_id)"
AZURE_TENANT="$(get vault_azure_tenant_id)"
unset vault

for name in AZURE_CLIENT_ID AZURE_SECRET AZURE_SUBSCRIPTION_ID AZURE_TENANT; do
  if [ -n "${!name}" ]; then export "$name"; else unset "$name"; fi
done

exec "$@"
