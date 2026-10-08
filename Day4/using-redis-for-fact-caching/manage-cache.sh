ansible-playbook magic.yml --flush-cache     # discard the cache and gather again
ansible-config dump --only-changed           # confirm which cache settings are active
