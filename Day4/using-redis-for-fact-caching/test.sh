ansible-playbook magic.yml
redis-cli keys 'ansible_facts_*'
redis-cli ttl ansible_facts_win2022
redis-cli get ansible_facts_win2022 | python3 -m json.tool | head -20
