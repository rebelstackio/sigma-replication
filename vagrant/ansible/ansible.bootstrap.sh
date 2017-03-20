#!/bin/bash -e

# Hosts files
HOSTS=/etc/hosts

# Node version duh
NODE_VER=5.x

print_db_usage () {
	echo "Your Ansible test environment has been setup"
	echo "  Host: $GUEST_IP  [ ansible.testing ]"
	echo "  Guest IP: $GUEST_IP"
	echo "    added:   \"ansible.testing   $GUEST_IP\"   to /etc/hosts"
	echo ""
  echo "  NodeJS v:$NODE_VER"
  echo ""
	echo "  Getting into the box (terminal):"
	echo "  vagrant ssh ansible"
	echo ""
}

export DEBIAN_FRONTEND=noninteractive

PROVISIONED_ON=/etc/vm_provision_on_timestamp
if [ -f "$PROVISIONED_ON" ]
then
	echo "VM was already provisioned at: $(cat $PROVISIONED_ON)"
	echo "To run system updates manually login via 'vagrant ssh' and run 'apt-get update && apt-get upgrade'"
	echo ""
	print_db_usage
	exit
fi

chown vagrant $HOSTS
echo "$GUEST_IP   ansible.testing" >> $HOSTS
echo "$PGBOX_GUEST_IP   $PGBOX_FQDN" >> $HOSTS
echo "$PGBOX2_GUEST_IP   $PGBOX2_FQDN" >> $HOSTS

mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
chown -R vagrant:vagrant /home/vagrant/.ssh
su vagrant -c "ssh-keygen -t rsa -P '' -f /home/vagrant/.ssh/id_rsa"

mkdir -p /vagrant/files/ssh
cp /home/vagrant/.ssh/id_rsa.pub /vagrant/files/ssh/`hostname`.pub

sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update
sudo apt-get -y install ansible

# Tag the provision time:
date > "$PROVISIONED_ON"

echo "Successfully created dev virtual machine with Ansible"
echo ""
print_db_usage
