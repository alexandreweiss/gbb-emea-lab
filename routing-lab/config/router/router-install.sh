# Install ansible
sudo apt-add-repository ppa:ansible/ansible -y
sudo apt update
sudo apt install ansible -f

# Run playbook
ansible-playbook $PWD/ans-router.yml -c local -i $PWD/ans-inventory.yml --extra-vars "storageAccount=$storageAccount"