variable "prefix" {
  description = "Prefix for all Azure resource names"
  type        = string
  default     = "demo"
}

variable "existing_resource_group_name" {
  description = "Name of an existing resource group to deploy into. Leave null to create <prefix>-rg"
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region. Null means: the region of the existing resource group, or centralindia for a new one"
  type        = string
  default     = null
}

variable "vm_size" {
  description = "Size of all three VMs"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin user on all three VMs"
  type        = string
  default     = "azureuser"
}

variable "windows_admin_password" {
  description = "Windows admin password. run.sh sets it from the vault as TF_VAR_windows_admin_password"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "RSA public key that Azure installs on the Linux VMs"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key_path" {
  description = "Matching private key that Ansible uses"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "allowed_source_cidr" {
  description = "CIDR allowed to reach SSH, WinRM and RDP. Leave null to use the public IP of this machine"
  type        = string
  default     = null
}
