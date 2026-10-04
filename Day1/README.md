# Day 1

## Info - Download the cloud images to provision ansible node VMs
<pre>
mkdir -p ~/cloud-images && cd ~/cloud-images
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
wget https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2  
</pre>

## Lab - Install tools required for Day1 labs

```
# Install Terraform in Ubuntu
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update
sudo apt-get install terraform

# Install KVM Hypervisor in Ubuntu
sudo apt update
#sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients
sudo apt install -y qemu-system-x86 libvirt-daemon-system libvirt-clients
sudo usermod -aG libvirt $USER    # log out and log in again

# A fresh install often has no "default" storage pool. Check first:
virsh -c qemu:///system pool-list --all

# Create it only if it is missing:
virsh -c qemu:///system pool-define-as default dir --target /var/lib/libvirt/images
virsh -c qemu:///system pool-start default
virsh -c qemu:///system pool-autostart default

# Clone TekTutor Training repository
cd ~
git clone https://github.com/tektutor/ansible-oct-2026.git
cd ~/ansible-oct-2026/Day1
tree kvm-lab
cd kvm-lab
terraform init
terraform apply
terraform output vm_ips
terraform output -raw ansible_inventory > inventory
```



