#!/bin/bash
# Promoting a postgres box to primary node.
# NOTE: The script should be executed as postgres user

echo "initiate_replication - Start"
cd "$(dirname "$0")"
pwd
# Defining default values

. ../clusterips

primary_host=$his_ip
primary_port={{ PGPORT }}
slot_name="{{ primary_slot_name }}"

replication_user="{{ PG_REPUSER }}"
replication_password="{{ PG_REPPASS }}"

force=false

debug=true

# Ensuring that 'postgres' runs the script
if [ "$(id -u)" -ne "$(id -u postgres)" ]; then

	echo "ERROR: The script must be executed as 'postgres' user."
	exit 1

fi

if [ "$primary_host" = "" ]; then

	echo "ERROR: Primary host is mandatory. For help execute 'initiate_replication -h'"
	exit 2

fi

if [ "$replication_password" = "" ]; then

	echo "ERROR: --password is mandatory. For help execute 'initiate_replication -h'"
	exit 2

fi

if $debug; then

	echo "DEBUG: The script will be executed with the following arguments:"
	echo "DEBUG: --primary-host=$primary_host"
	echo "DEBUG: --primary-port=$primary_port"
	echo "DEBUG: --slot-name=$slot_name"
	echo "DEBUG: --user=$replication_user"
	echo "DEBUG: --password=$replication_password"

	if $force; then
		echo "DEBUG: --force"
	fi

fi

echo "INFO: Ensuring replication user and password in password file (.pgpass)..."
password_line="*:*:*:${replication_user}:${replication_password}"

if [ ! -f /var/lib/postgresql/.pgpass ]; then

	echo $password_line >> /var/lib/postgresql/.pgpass

elif ! grep -q "$password_line" /var/lib/postgresql/.pgpass ; then

	sed -i -e '$a\' /var/lib/postgresql/.pgpass
	echo $password_line >> /var/lib/postgresql/.pgpass
	sed -i -e '$a\' /var/lib/postgresql/.pgpass

fi

chown postgres:postgres /var/lib/postgresql/.pgpass
chmod 0600 /var/lib/postgresql/.pgpass

success=false

echo "INFO: Creating replication slot at the primary server..."
ssh -T postgres@$primary_host /etc/postgresql/{{ PGVERSION }}/main/replscripts/create_slot.sh && success=true

if ! $success ; then

	echo "ERROR: Creating replication slot at the primary server failed."
	exit 5

fi

service postgresql stop

if [ -d /var/lib/postgresql/{{ PGVERSION }}/main ]; then

	echo "INFO: Deleting old data..."

	success=false
	rm -rf /var/lib/postgresql/{{ PGVERSION }}/main && success=true

	if ! $success ; then

		echo "ERROR: Deleting data directory failed."
		exit 6

	fi

fi

echo "INFO: Getting the initial backup..."

success=false
pg_basebackup -D /var/lib/postgresql/{{ PGVERSION }}/main -h $primary_host -p $primary_port -U $replication_user && success=true

if ! $success; then

	echo "ERROR: Initial backup failed."
	exit 5

fi

if [ -e /var/lib/postgresql/{{ PGVERSION }}/main/recovery.conf ]; then

	echo "INFO: Removing old recovery.conf file..."

	success=false
	rm /var/lib/postgresql/{{ PGVERSION }}/main/recovery.conf && success=true

	if ! $success; then

		echo "ERROR: Removing old recovery.conf failed."
		exit 4

	fi

fi

echo "INFO: Creating recovery.conf file..."
cat >/var/lib/postgresql/{{ PGVERSION }}/main/recovery.conf <<EOL
standby_mode       = 'on'
primary_slot_name  = '${slot_name}'
primary_conninfo   = 'host=${primary_host} port=${primary_port} user=${replication_user} password=${replication_password}'
EOL

chown postgres:postgres /var/lib/postgresql/{{ PGVERSION }}/main/recovery.conf
chmod 0644 /var/lib/postgresql/{{ PGVERSION }}/main/recovery.conf

if [ -e /etc/postgresql/{{ PGVERSION }}/main/postgresql.conf ]; then

	echo "INFO: Removing old postgresql.conf file..."

	success=false
	rm /etc/postgresql/{{ PGVERSION }}/main/postgresql.conf && success=true

	if ! $success; then

		echo "ERROR: Removing old postgresql.conf failed."
		exit 4

	fi

fi

echo "INFO: Copying new postgresql.conf file..."

success=false
cp /etc/postgresql/{{ PGVERSION }}/main/repltemplates/postgresql.conf.standby /etc/postgresql/{{ PGVERSION }}/main/postgresql.conf && success=true

if ! $success; then

	echo "ERROR: Copying new postgresql.conf failed."
	exit 4

fi

chown postgres:postgres /etc/postgresql/{{ PGVERSION }}/main/postgresql.conf
chmod 0644 /etc/postgresql/{{ PGVERSION }}/main/postgresql.conf

echo "INFO: Starting postgresql service..."
service postgresql start

echo "initiate_replication - Done!"
exit 0
