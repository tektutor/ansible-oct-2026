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

## Lab - Running ansible ad-hoc commands
```
cd ~/ansible-oct-2026
git pull
cd Day1/ansible
cat inventory
docker ps

ansible -i inventory all -m ping
ansible -i inventory ubuntu -m ping
ansible -i inventory rocky -m ping
ansible -i inventory all -m shell -a "hostname"
ansible -i inventory all -m shell -a "hostname -i"
```
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/52b792ea-0c55-4edf-ac56-cf5efec56939" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/e6f90c17-ce1d-44c4-967f-8702256dcd83" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/826fbf1c-59ff-4064-8d65-d2136acaa14a" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/10efff15-cc6a-42b7-9c0c-24e6b8eb9511" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/64b95179-8654-433d-8e0c-67cb0d4c5bfb" />


## Lab - Running your first ansible playbook
```
cd ~/ansible-oct-2026
git pull
cd Day1/ansible
cat inventory
cat install-nginx-playbook.yml

ansible-playbook -i inventory install-nginx-playbook.yml

# Test
curl http://localhost:8001
curl http://localhost:8002
curl http://localhost:8003
curl http://localhost:8004

```

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/28a35e5f-af85-4321-b315-3e0244fb8df7" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/4674c0d2-2a70-43f7-a456-41a18ccde9a5" />
