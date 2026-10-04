locals {
  vm_ips = {
    for name, d in data.libvirt_domain_interface_addresses.vm :
    name => try([for a in d.interfaces[0].addrs : a.addr if a.type == "ipv4"][0], null)
  }
}

output "vm_ips" {
  description = "IPv4 address of each VM."
  value       = local.vm_ips
}

output "ssh_commands" {
  description = "Ready-to-use SSH command for each VM."
  value       = { for name, ip in local.vm_ips : name => "ssh ${var.admin_user}@${ip}" if ip != null }
}

output "ansible_inventory" {
  description = "INI inventory. Save it with: terraform output -raw ansible_inventory > inventory"
  value = join("\n", concat(
    ["[ubuntu]"],
    [for name, ip in local.vm_ips : "${name} ansible_host=${ip} ansible_user=${var.admin_user}" if var.vms[name].os == "ubuntu2404" && ip != null],
    ["", "[rocky]"],
    [for name, ip in local.vm_ips : "${name} ansible_host=${ip} ansible_user=${var.admin_user}" if var.vms[name].os == "rocky9" && ip != null],
    [""]
  ))
}
