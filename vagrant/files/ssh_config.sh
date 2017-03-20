#!/bin/bash

# Add boxes to known hosts to avoid the security question.
#
vagrant ssh ansible -c /vagrant/files/add_ssh_hosts.sh

# Copy ansible public key to the authorized keys file.
#
vagrant ssh pgyin -c /vagrant/files/set_up_ssh_keys.sh
vagrant ssh pgyang -c /vagrant/files/set_up_ssh_keys.sh
