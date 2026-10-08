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

## Lab - Some useful ansible hacks
```
cd ~/ansible-oct-2026
git pull
cd Day3/windows/windows-health-check-with-html-report

ansible-playbook -i inventory.ini playbook.yml --syntax-check
ansible-playbook -i inventory.ini playbook.yml --list-hosts
ansible-playbook -i inventory.ini playbook.yml --list-tasks
ansible-playbook -i inventory.ini playbook.yml --check --diff
ansible-playbook -i inventory.ini playbook.yml
```

## Lab - Selective Execution with Tags
```
cd ~/ansible-oct-2026
git pull
cd Day4/tags

# Inspect without running
ansible-playbook -i inventory.ini site.yml --syntax-check
ansible-playbook -i inventory.ini site.yml --list-tags
ansible-playbook -i inventory.ini site.yml --list-tasks

# Run playbook on all nodes
ansible-playbook -i inventory.ini site.yml

# Using --limit
ansible-playbook -i inventory.ini site.yml --tags verify --limit rocky
ansible-playbook -i inventory.ini site.yml --tags config --limit ubuntu1-jegan
ansible-playbook -i inventory.ini site.yml --tags debug --limit 'app:!rocky'
```
