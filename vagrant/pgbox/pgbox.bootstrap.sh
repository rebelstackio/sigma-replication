#!/bin/bash -e
set -a
. /vagrant/files/pgconfig
BASH_DIR='/vagrant/scripts/'
LOG=/vagrant/tmp/log/boot.log
set +a

. ${BASH_DIR}util.sh

mkdir -p /vagrant/tmp/log

# Hosts files
HOSTS=/etc/hosts

print_db_usage () {
	echo "***********************************************************************"
	echo ""
	echo "Your postgres environment has been setup:"
	echo ""
	echo "  Host: $EXTIP  [ $FQDN ]"
	echo "  External IP: $EXTIP"
	echo "    added:   \"$FQDN   $EXTIP\"   to /etc/hosts"
	echo ""
	echo ""
	echo " Database:"
	echo "  Port: $PGPORT  PoolPort: $PGPOOLPORT"
	echo "  Database: $PGDATABASE"
	echo "  Username: $PGUSER"
	echo "  Password: $PGPASSWORD"
	echo ""
	echo "Admin access to postgres user via VM:"
	echo "  vagrant ssh"
	echo "  sudo su - postgres"
	echo ""
	echo "psql access to app database user via VM:"
	echo "  vagrant ssh"
	echo "  sudo su - postgres"
	echo "  PGUSER=$PGUSER PGPASSWORD=$PGPASSWORD psql -h localhost $PGDATABASE"
	echo "  or simply: psql"
	echo ""
	echo ""
	echo "Env variable for application development:"
	echo "  DATABASE_URL=postgresql://$PGUSER:$PGPASSWORD@*:5432/$PGDATABASE"
	echo ""
	echo "Local command to access the database via psql:"
	echo "  PGUSER=$PGUSER PGPASSWORD=$PGPASSWORD psql -h localhost -p 5432 $PGDATABASE"
	echo ""
	echo "  Getting into the box (terminal):"
	echo "  vagrant ssh"
	echo "  sudo su - postgres"
	echo ""
	echo "***********************************************************************"
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

# display "Setting Timezone & Locale to $TZ & C.UTF-8"
#
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

echo "export LANG=C.UTF-8" >> /home/vagrant/.bashrc
echo "export LC_ALL=C.UTF-8" >> /home/vagrant/.bashrc

# chown vagrant /etc/hosts
# echo "$EXTIP   $FQDN" >> /etc/hosts
# echo "$BUSIP   bus.$FQDN" >> /etc/hosts

# install postgres
. $BASH_DIR/pgsql.sh
. $BASH_DIR/deploy.sh

# Tag the provision time:
date > "$PROVISIONED_ON"

display "Successfully created $FQDN with Postgres"

print_db_usage
