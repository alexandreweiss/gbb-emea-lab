# Retieve variables
vm_hostname=${1}

# Install ansible
sudo apt-add-repository ppa:ansible/ansible -y
sudo apt-get update -y
sudo apt-get install ansible -y

# Run playbook
ansible-playbook $PWD/ans-router.yml -c local -i $PWD/ans-inventory.yml --extra-vars "vm_hostname=$vm_hostname"