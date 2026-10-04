terraform {
  required_version = ">= 1.6.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9.9"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_uri
}

locals {
  # Official cloud images. Both ship with cloud-init and Python 3.
  images = {
    ubuntu2404 = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    rocky9     = "https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
  }

  # Download only the images that var.vms really uses.
  used_images = toset([for vm in values(var.vms) : vm.os])

  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
}

# One read-only base image per operating system.
resource "libvirt_volume" "base" {
  for_each = local.used_images

  name = "${each.key}-base.qcow2"
  pool = var.storage_pool

  target = {
    format = {
      type = "qcow2"
    }
  }

  create = {
    content = {
      url = local.images[each.key]
    }
  }
}

# One copy-on-write system disk per VM. It stores only the changes
# on top of the base image, so each VM starts at a few MB on the host.
resource "libvirt_volume" "disk" {
  for_each = var.vms

  name     = "${each.key}.qcow2"
  pool     = var.storage_pool
  capacity = each.value.disk_gib * 1024 * 1024 * 1024 # bytes

  target = {
    format = {
      type = "qcow2"
    }
  }

  backing_store = {
    path = libvirt_volume.base[each.value.os].path
    format = {
      type = "qcow2"
    }
  }
}

# cloud-init seed: sets the hostname, creates the admin user, installs the SSH key.
resource "libvirt_cloudinit_disk" "seed" {
  for_each = var.vms

  name = "${each.key}-seed"

  user_data = join("\n", [
    "#cloud-config",
    yamlencode({
      hostname          = each.key
      preserve_hostname = false
      ssh_pwauth        = false
      users = [
        {
          name                = var.admin_user
          groups              = each.value.os == "ubuntu2404" ? ["sudo"] : ["wheel"]
          shell               = "/bin/bash"
          sudo                = "ALL=(ALL) NOPASSWD:ALL"
          lock_passwd         = true
          ssh_authorized_keys = [local.ssh_public_key]
        }
      ]
    })
  ])

  meta_data = yamlencode({
    "instance-id"    = each.key
    "local-hostname" = each.key
  })
}

# Upload the seed ISO into the storage pool so the VM can attach it.
resource "libvirt_volume" "seed" {
  for_each = var.vms

  name = "${each.key}-seed.iso"
  pool = var.storage_pool

  create = {
    content = {
      url = libvirt_cloudinit_disk.seed[each.key].path
    }
  }
}

resource "libvirt_domain" "vm" {
  for_each = var.vms

  name      = each.key
  type      = "kvm"
  vcpu      = each.value.vcpu
  memory    = each.value.memory_mib * 1024 # libvirt default unit is KiB
  running   = true
  autostart = var.autostart

  # Rocky 9 needs an x86-64-v2 CPU. The default QEMU CPU model is older,
  # and the Rocky kernel panics on it. host-passthrough exposes the host CPU.
  cpu = {
    mode = "host-passthrough"
  }

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  devices = {
    disks = [
      {
        source = {
          volume = {
            pool   = libvirt_volume.disk[each.key].pool
            volume = libvirt_volume.disk[each.key].name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
        driver = {
          type = "qcow2"
        }
      },
      {
        device = "cdrom"
        source = {
          volume = {
            pool   = libvirt_volume.seed[each.key].pool
            volume = libvirt_volume.seed[each.key].name
          }
        }
        target = {
          dev = "sda"
          bus = "sata"
        }
      }
    ]

    interfaces = [
      {
        type  = "network"
        model = { type = "virtio" }
        source = {
          network = {
            network = var.network_name
          }
        }
        # Block "terraform apply" until the VM gets a DHCP lease.
        wait_for_ip = {
          timeout = 300
          source  = "lease"
        }
      }
    ]

    graphics = [
      {
        vnc = {
          auto_port = true
          listen    = "127.0.0.1"
        }
      }
    ]
  }
}

# Read the DHCP lease of each VM for the outputs.
data "libvirt_domain_interface_addresses" "vm" {
  for_each = var.vms

  domain = libvirt_domain.vm[each.key].id
  source = "lease"
}
