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
sudo chown -R $USER: .
sudo journalctl -k --since "30 min ago" | grep 'apparmor="DENIED"'
echo '/var/lib/libvirt/images/** rwk,' | sudo tee -a /etc/apparmor.d/local/abstractions/libvirt-qemu
sudo systemctl restart libvirtd
echo '/var/lib/libvirt/images/** rwk,' | sudo tee -a /etc/apparmor.d/local/abstractions/libvirt-qemu
sudo systemctl restart libvirtd
sudo sed -i 's/^#\?security_driver = .*/security_driver = "none"/' /etc/libvirt/qemu.conf
grep '^security_driver' /etc/libvirt/qemu.conf    # must print: security_driver = "none"
sudo systemctl restart libvirtd

echo 'security_driver = "none"' | sudo tee -a /etc/libvirt/qemu.conf
sudo grep -n 'security_driver' /etc/libvirt/qemu.conf

systemctl is-active libvirtd virtqemud
sudo systemctl restart libvirtd      # if libvirtd is active
sudo systemctl restart virtqemud     # if virtqemud is active
terraform apply


cd kvm-lab
terraform init
terraform apply
terraform output vm_ips
terraform output -raw ansible_inventory > inventory
ssh-keygen -R 192.168.122.237
ssh-keygen -R 192.168.122.237
ssh-keyscan -H 192.168.122.237 192.168.122.244 >> ~/.ssh/known_hosts
ansible -i inventory all -m ping
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/3933e9e8-d406-4130-b0b0-029fa07711f5" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/a9932795-79ee-47b3-b5ae-48c96276cc47" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/d527e340-c115-4534-af96-48e78068f00a" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/b6d6acad-c50c-4c47-a282-b4be6e013a00" />


## Lab - Building a Custom Docker Image
Under your linux home directory
```
cd ~
mkdir -p CustomDockerAnsibleNodeImages/{ubuntu,rocky}
cd CustomDockerAnsibleNodeImages/ubuntu
touch Dockerfile
```

Create a file named Dockerfile with the below content

```
FROM ubuntu:24.04
MAINTAINER Jeganathan Swaminathan <jegan@tektutor.org>

RUN apt-get update && apt-get install -y openssh-server python3
RUN mkdir -p /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

RUN mkdir -p /root/.ssh
COPY authorized_keys /root/.ssh/authorized_keys

EXPOSE 22
EXPOSE 80 
CMD ["/usr/sbin/sshd", "-D"]
```

