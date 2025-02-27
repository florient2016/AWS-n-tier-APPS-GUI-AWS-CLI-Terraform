#!/bin/bash

# Test if necessary packages are installed
for pkg in vim git bash-completion wget tmux yum-utils device-mapper-persistent-data lvm2 go python3-pip sshpass; do
    if ! rpm -q $pkg &> /dev/null; then
        echo "Package $pkg is not installed"
        exit 1
    fi
done
echo "All necessary packages are installed"

# Test if the ansible user is created
if id "ansible" &> /dev/null; then
    echo "User ansible exists"
else
    echo "User ansible does not exist"
    exit 1
fi

# Test if sudoers file for ansible is configured correctly
if sudo grep -q 'ansible  ALL=(ALL:ALL) NOPASSWD:ALL' /etc/sudoers.d/ansible; then
    echo "Sudoers file for ansible is configured correctly"
else
    echo "Sudoers file for ansible is not configured correctly"
    exit 1
fi

# Test if SSH configuration is modified correctly
if sudo grep -q 'PermitRootLogin yes' /etc/ssh/sshd_config && sudo grep -q 'PasswordAuthentication yes' /etc/ssh/sshd_config; then
    echo "SSH configuration is modified correctly"
else
    echo "SSH configuration is not modified correctly"
    exit 1
fi

# Test if the hostname is set to ansible
if [ "$(hostname)" == "ansible" ]; then
    echo "Hostname is set to ansible"
else
    echo "Hostname is not set to ansible"
    exit 1
fi

# Test if /etc/hosts file contains the correct entries
if grep -q 'webserver.example.com' /etc/hosts && grep -q 'bdd.example.com' /etc/hosts; then
    echo "/etc/hosts file contains the correct entries"
else
    echo "/etc/hosts file does not contain the correct entries"
    exit 1
fi

# Test if inventory file is created correctly
if [ -f /home/ansible/inventory ] && grep -q '[webserver]' /home/ansible/inventory && grep -q '[bdd]' /home/ansible/inventory; then
    echo "Inventory file is created correctly"
else
    echo "Inventory file is not created correctly"
    exit 1
fi

# Test if ansible.cfg file is created correctly
if [ -f /home/ansible/ansible.cfg ] && grep -q '[defaults]' /home/ansible/ansible.cfg && grep -q '[privilege_escalation]' /home/ansible/ansible.cfg; then
    echo "ansible.cfg file is created correctly"
else
    echo "ansible.cfg file is not created correctly"
    exit 1
fi

# Test if the ownership of /home/ansible is set to ansible
if [ "$(stat -c %U /home/ansible)" == "ansible" ]; then
    echo "Ownership of /home/ansible is set to ansible"
else
    echo "Ownership of /home/ansible is not set to ansible"
    exit 1
fi

# Test if SSH key pair is generated for ansible user
if [ -f /home/ansible/.ssh/id_rsa ] && [ -f /home/ansible/.ssh/id_rsa.pub ]; then
    echo "SSH key pair is generated for ansible user"
else
    echo "SSH key pair is not generated for ansible user"
    exit 1
fi

echo "All tests passed successfully"