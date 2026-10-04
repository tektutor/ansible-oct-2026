variable "libvirt_uri" {
  description = "Libvirt connection URI. Use qemu+ssh://user@host/system for a remote KVM host."
  type        = string
  default     = "qemu:///system"
}

variable "storage_pool" {
  description = "Existing libvirt storage pool for the images and disks."
  type        = string
  default     = "default"
}

variable "network_name" {
  description = "Existing libvirt network with DHCP."
  type        = string
  default     = "default"
}

variable "admin_user" {
  description = "User that cloud-init creates in every VM, with passwordless sudo."
  type        = string
  default     = "ansible"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key that cloud-init installs for the admin user."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "autostart" {
  description = "Start the VMs when the KVM host boots."
  type        = bool
  default     = false
}

variable "vms" {
  description = "VMs to create. The map key becomes the VM name and the hostname."
  type = map(object({
    os         = string
    vcpu       = optional(number, 2)
    memory_mib = optional(number, 2048)
    disk_gib   = optional(number, 20)
  }))

  default = {
    ubuntu1 = { os = "ubuntu2404" }
    rocky1  = { os = "rocky9" }
  }

  validation {
    condition     = alltrue([for vm in values(var.vms) : contains(["ubuntu2404", "rocky9"], vm.os)])
    error_message = "The os value must be \"ubuntu2404\" or \"rocky9\"."
  }

  validation {
    # The Rocky 9 cloud image has a 10 GiB virtual disk. A smaller overlay fails.
    condition     = alltrue([for vm in values(var.vms) : vm.disk_gib >= 10])
    error_message = "The disk_gib value must be 10 or more."
  }
}
