#!/bin/bash
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
sudo echo "WEB SERVER 1" > /var/www/html/index.html
sudo yum install -y vim git bash-completion wget tmux yum-utils device-mapper-persistent-data lvm2 go python3-pip sshpass
sudo useradd -m -d /home/ansible ansible -G wheel
sudo pip3 install ansible
sudo echo 'ansible  ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/ansible
sudo chown ansible:ansible /etc/sudoers.d/ansible
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/gI' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/gI' /etc/ssh/sshd_config
echo "ansible:ceph" | sudo chpasswd
sudo hostnamectl hostname ansible
sudo systemctl restart sshd
sudo echo 'ansible  ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers

sudo tee -a /etc/hosts << TTH
x1 webserver.example.com  ansible
x2 bdd.example.com  ansible
TTH

cat > /home/ansible/inventory << EOF
[webserver]
ansible
[bdd]
ansible
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

sudo chown -R ansible:ansible /home/ansible

sudo runuser -l ansible -c 'ssh-keygen -t rsa -b 2048 -f /home/ansible/.ssh/id_rsa -N ""'
sudo runuser -l ansible -c 'ansible-galaxy collection install community.general'
sudo runuser -l ansible -c 'ansible-galaxy collection install community.postgresql'
#sudo sed -i 's/x1/WebserverIP/gI' /etc/hosts
#sudo sed -i 's/x2/BddIP/gI' /etc/hosts