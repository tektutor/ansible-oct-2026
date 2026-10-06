# Day 2

## Info - How to create a Windows VM using KVM Hypervisor on Ubuntu ( You don't have to do this - this is just for your future reference )
```
sudo cp ~/Downloads/SERVER_EVAL_x64FRE_en-us.iso /var/lib/libvirt/images/

sudo virt-install \
  --name win2022 \
  --memory 8192 \
  --vcpus 4 \
  --cpu host-passthrough \
  --os-variant win2k22 \
  --disk path=/var/lib/libvirt/images/win2022.qcow2,size=60,format=qcow2,bus=sata \
  --cdrom /var/lib/libvirt/images/SERVER_EVAL_x64FRE_en-us.iso \
  --network network=default,model=e1000e \
  --graphics vnc,listen=127.0.0.1 \
  --noautoconsole
```

## Lab - Connect to your Ubuntu terminal
See if the custom docker images are present
```
docker images
```

See if the containers are there
```
docker ps -a
```

Start all 4 containers
```
docker start ubuntu1 ubuntu2 rocky1 rocky2
docker ps
```

Check if you can SSH into those containers
```
ssh -p 2001 root@localhost
exit

ssh -p 2002 root@localhost
exit

ssh -p 2003 root@localhost
exit

ssh -p 2004 root@localhost
exit
```

## Lab - Installing Ansible
```
sudo apt update && apt install -y ansible-core
ansible --version
```

## Lab - Finding ansible module help
```
# List all ansible modules ( press letter q to come out )
ansible-doc -l

# Find details of a specific ansible module
ansible-doc apt
ansible-doc service
ansible-doc command
ansible-doc yum
ansible-doc file
ansible-doc template
```
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/78a687d9-ef3b-492e-bfb2-ff90f5ad412f" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/2834a7de-7e09-4643-a8f2-ffc288fd14af" />
