#!/bin/bash

# Copy the public keys to the authorized keys file.
#
cat /vagrant/files/ssh/ansible.pub >> /home/vagrant/.ssh/authorized_keys
