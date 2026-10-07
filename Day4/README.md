# Day 4

## Lab - Ansible Inventory Graph and List
```
cd ~/ansible-oct-2026
git pull
cd Day3/windows/windows-health-check-with-html-report
ansible-inventory -i inventory.ini --graph
ansible-inventory -i inventory.ini --graph --vars
ansible-inventory -i inventory.ini --graph windows
ansible-inventory -i inventory.ini --list
ansible-inventory -i inventory.ini --list --yaml
ansible-inventory -i inventory.ini --host win2022
ansible-inventory -i inventory.ini --list --yaml --output inventory.yml
```
