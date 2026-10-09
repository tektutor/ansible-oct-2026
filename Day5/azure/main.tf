locals {
  linux_vms = {
    ubuntu = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
    }
    rhel = {
      publisher = "RedHat"
      offer     = "RHEL"
      sku       = "9-lvm-gen2"
    }
  }

  all_vms = toset(["ubuntu", "rhel", "windows"])

  use_existing_rg = var.existing_resource_group_name != null
  rg_name         = local.use_existing_rg ? data.azurerm_resource_group.existing[0].name : azurerm_resource_group.rg[0].name
  rg_location = coalesce(
    var.location,
    local.use_existing_rg ? data.azurerm_resource_group.existing[0].location : "centralindia"
  )

  source_cidr = coalesce(
    var.allowed_source_cidr,
    try("${chomp(data.http.my_ip[0].response_body)}/32", null)
  )

  # Runs once on the Windows VM and opens a WinRM HTTPS listener for Ansible.
  winrm_setup = <<-PS
    $ErrorActionPreference = 'Stop'
    Enable-PSRemoting -Force -SkipNetworkProfileCheck
    $cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation Cert:\LocalMachine\My
    Get-ChildItem WSMan:\localhost\Listener | Where-Object { $_.Keys -contains 'Transport=HTTPS' } | Remove-Item -Recurse -Force
    New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $cert.Thumbprint -Force
    if (-not (Get-NetFirewallRule -DisplayName 'WinRM HTTPS' -ErrorAction SilentlyContinue)) {
      New-NetFirewallRule -DisplayName 'WinRM HTTPS' -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow
    }
    Set-Service WinRM -StartupType Automatic
    Restart-Service WinRM
  PS
}

data "http" "my_ip" {
  count = var.allowed_source_cidr == null ? 1 : 0
  url   = "https://api.ipify.org"
}

# ---------------------------------------------------------------- network

# Set existing_resource_group_name to deploy into a resource group that
# already exists (lab and sandbox accounts). Leave it null to create one.
data "azurerm_resource_group" "existing" {
  count = var.existing_resource_group_name == null ? 0 : 1
  name  = var.existing_resource_group_name
}

resource "azurerm_resource_group" "rg" {
  count    = var.existing_resource_group_name == null ? 1 : 0
  name     = "${var.prefix}-rg"
  location = coalesce(var.location, "centralindia")
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = local.rg_location
  resource_group_name = local.rg_name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = local.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = local.rg_location
  resource_group_name = local.rg_name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = local.source_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "winrm-https"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = local.source_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "rdp"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = local.source_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_public_ip" "pip" {
  for_each            = local.all_vms
  name                = "${var.prefix}-${each.key}-pip"
  location            = local.rg_location
  resource_group_name = local.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  for_each            = local.all_vms
  name                = "${var.prefix}-${each.key}-nic"
  location            = local.rg_location
  resource_group_name = local.rg_name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[each.key].id
  }
}

# ---------------------------------------------------------------- Linux VMs

resource "azurerm_linux_virtual_machine" "linux" {
  for_each                        = local.linux_vms
  name                            = "${var.prefix}-${each.key}-vm"
  computer_name                   = each.key
  location                        = local.rg_location
  resource_group_name             = local.rg_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.nic[each.key].id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
    version   = "latest"
  }
}

# ---------------------------------------------------------------- Windows VM

resource "azurerm_windows_virtual_machine" "windows" {
  name                  = "${var.prefix}-windows-vm"
  computer_name         = "windows"
  location              = local.rg_location
  resource_group_name   = local.rg_name
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.windows_admin_password
  network_interface_ids = [azurerm_network_interface.nic["windows"].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "winrm" {
  name                 = "enable-winrm-https"
  virtual_machine_id   = azurerm_windows_virtual_machine.windows.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  protected_settings = jsonencode({
    commandToExecute = "powershell -NoProfile -ExecutionPolicy Bypass -EncodedCommand ${textencodebase64(local.winrm_setup, "UTF-16LE")}"
  })
}

# ---------------------------------------------------------------- Ansible

resource "local_file" "inventory" {
  filename        = "${path.module}/ansible/inventory.ini"
  file_permission = "0644"
  content = templatefile("${path.module}/inventory.tftpl", {
    ubuntu_ip       = azurerm_public_ip.pip["ubuntu"].ip_address
    rhel_ip         = azurerm_public_ip.pip["rhel"].ip_address
    windows_ip      = azurerm_public_ip.pip["windows"].ip_address
    admin_username  = var.admin_username
    ssh_private_key = pathexpand(var.ssh_private_key_path)
  })
}

# Runs the playbook after the VMs exist. It runs again when a VM is
# replaced or when you change site.yml.
resource "terraform_data" "ansible" {
  triggers_replace = [
    azurerm_linux_virtual_machine.linux["ubuntu"].id,
    azurerm_linux_virtual_machine.linux["rhel"].id,
    azurerm_windows_virtual_machine.windows.id,
    filesha256("${path.module}/ansible/site.yml"),
  ]

  depends_on = [
    local_file.inventory,
    azurerm_virtual_machine_extension.winrm,
    azurerm_subnet_network_security_group_association.nsg,
  ]

  provisioner "local-exec" {
    working_dir = "${path.module}/ansible"
    command     = "ansible-playbook -i inventory.ini site.yml"
  }
}
