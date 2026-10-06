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
