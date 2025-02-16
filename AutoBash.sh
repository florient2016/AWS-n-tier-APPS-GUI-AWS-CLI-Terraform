#!/bin/bash
sudo yum install -y vim git bash-completion wget tmux 
sudo yum install -y vim yum-utils device-mapper-persistent-data lvm2 go
sudo yum install vim python3-pip git sshpass yum-utils lvm2  -y
sudo pip3 install ansible
sudo useradd -m -d /home/ansible ansible -G wheel
sudo echo 'ansible  ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/ansible
sudo echo ceph | passwd --stdin ansible
sudo chown ansible:ansible /etc/sudoers.d/ansible
sudo chown ansible:ansible /home/ansible/*
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/gI' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/gI' /etc/ssh/sshd_config
sudo systemctl restart sshd
sudo echo 'ansible  ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers

cat > /home/ansible/inventory << EOF
[webserver]
webserver
[bddservers]
bdd
EOF

cat > /home/ansible/ansible.cfg << EOL
[defaults]
inventory = /home/ansible/inventory
host_key_checking = false
remote_user = ansible
[privilege_escalation]
become = true
become_user = root
become_ask_pass = false
become_method = sudo
EOL