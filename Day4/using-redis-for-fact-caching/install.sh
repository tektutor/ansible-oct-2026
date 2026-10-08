sudo apt install redis-server
sudo systemctl enable --now redis-server
pip install redis                                   # inside your ansible-venv
ansible-galaxy collection install community.general
