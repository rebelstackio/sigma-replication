# Vagrant

Vagrant project for development and testing of ansible playbooks for postgres replication development. As it stands this project will spin up a VirtualBox VM with ansible installed and sync the playbook directory to `~/playbooks` in order to give a the development team the same environment in which to run and test these playbooks.

## Getting started

- Install [vagrant](https://www.vagrantup.com/docs/installation/) and [VirtualBox](https://www.virtualbox.org/manual/ch02.html) on your machine
- Locate to `cloned-project/vagrant` directory
- execute: `$ vagrant up`

Using vagrant up without a "_box_name_" parameter instances both the `pgcom` and `pgjunta` VMs. These two boxes on first run are Ubuntu linux boxes with a base installation of postgresql.

Running `vagrant up ansible` will bring up (and provision on first run) the ansible server used to configure the two postgres boxes to be a master slave replication cluster.

### First run

The first time we bring up the VMs, vagrant will provision the boxes using the relevant `[boxtype].boostrap.sh` script in the `[boxtype]/` directory. The first build may take a few minutes but subsequent runs will be much faster. Once the provisioning of all three boxes has completed, it is required to manually run the script `files/ssh_config.sh` in order to configure password-less ssh communication between the ansible server and postgres VMs.

During the provisioning process bootstrap script will create public and private keys for the ansible server by running the following:

```sh
ansible/ansible.bootstrap.sh

# Add ssh keys and expose public key to other vagrant boxes
# We must run "vagrant ssh ansible -c /vagrant/files/set_up_ssh_keys.sh"
# after all the boxes are provisioned.

mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
chown -R vagrant:vagrant /home/vagrant/.ssh
su vagrant -c "ssh-keygen -t rsa -P '' -f /home/vagrant/.ssh/id_rsa"

mkdir -p /vagrant/files/ssh
cp /home/vagrant/.ssh/id_rsa.pub /vagrant/files/ssh/`hostname`.pub
```
and create entries in the `/etc/hosts` file for each of the know VMs:

```sh
ansible/ansible.bootstrap.sh

chown vagrant $HOSTS
echo "$GUEST_IP   ansible.testing" >> $HOSTS
echo "$PGBOX_GUEST_IP   $PGBOX_FQDN" >> $HOSTS
echo "$PGBOX2_GUEST_IP   $PGBOX2_FQDN" >> $HOSTS
```

We can copy the created keys to the other VMs using the following command from the repo's vagrant directory:

```sh
$ ./files/ssh_config.sh
```

*PLEASE NOTE* If you add any more VMs and require that they can communicate over ssh, add the the key generation and `/etc/hosts` configuration to your provisioning script and edit the [`set_up_ssh_keys.sh`](files/set_up_ssh_keys.sh) to know about your new hosts.

*PLEASE NOTE* If you subsequently add more VMs you will need to re-run the [`ssh_config.sh`](files/ssh_config.sh) script edited for all hosts that are required to communicate over ssh.

## Testing failover
First you should provision the two base boxes as shown above:

```sh
vagrant up
vagrant up ansible
./files/ssh_config.sh
```

This will give you two baseboxes that are not configured to as either slave or master, they just have postgres and the demo db installed.

Next, to replicate adding a new cluster to the network, we provision the boxes to be master and slave:
```sh
vagrant ssh ansible
cd playbooks
ansible-playbook pg_rep.yml -i hosts
```

This will copy all the tempates and scripts we need to promote a master and set up the replication, and it will call those scripts on both hosts. You will now have a replicating db. ssh into both boxes and run `sudo su postgres -c psql`  on the master instance of one box, add a database and you will be able to list in on the slave instance of the other box as well.
