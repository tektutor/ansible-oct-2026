output "public_ips" {
  description = "Public IP address of each VM"
  value       = { for name, pip in azurerm_public_ip.pip : name => pip.ip_address }
}

output "ssh_commands" {
  value = {
    for name in keys(local.linux_vms) :
    name => "ssh -i ${var.ssh_private_key_path} ${var.admin_username}@${azurerm_public_ip.pip[name].ip_address}"
  }
}
