time ansible-playbook magic.yml        # first run gathers facts
ls fact_cache/                         # one file per host, for example win2022
time ansible-playbook magic.yml        # second run skips "Gathering Facts"
