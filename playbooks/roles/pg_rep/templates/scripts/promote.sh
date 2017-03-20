#!/bin/bash
# Promoting standby to primary node
# NOTE: The script should be executed as postgres user

echo "promote - Start"

replication_user="{{ PG_REPUSER }}"
replication_password="{{ PG_REPPASS }}"

debug=true

success=false

# Ensuring that 'postgres' runs the script
if [ "$(id -u)" -ne "$(id -u postgres)" ]; then

	echo "ERROR: The script must be executed as 'postgres' user."
	exit 1

fi

if [ -e /var/lib/postgresql/{{ PGVERSION }}/main/recovery.conf ]; then

	echo "INFO: Deleting recovery.conf file..."

	success=false
	rm /var/lib/postgresql/{{ PGVERSION }}/main/recovery.conf && success=true

	if ! $success ; then

		echo "ERROR: Failed to delete '/var/lib/postgresql/{{ PGVERSION }}/main/recovery.conf' file."
		exit 4

	fi

fi

echo "INFO: Copying postgresql.conf"

success=false
cp /etc/postgresql/{{ PGVERSION }}/main/repltemplates/postgresql.conf.primary /etc/postgresql/{{ PGVERSION }}/main/postgresql.conf && success=true

if ! $success ; then

	echo "ERROR: Failed to copy new postgresql.conf file."
	exit 4

fi

if service postgresql status ; then

	echo "INFO: Restarting postgresql service..."
	service postgresql restart

else

	echo "INFO: Starting postgresql service..."
	service postgresql start

fi

echo "INFO: Ensuring replication role and password..."

success=false
rolecount=$(psql -Atc "SELECT count (*) FROM pg_roles WHERE rolname='${replication_user}';") && success=true

if ! $success ; then

	echo "ERROR: Failed to check existence of '${replication_user}' role."
	exit 5

fi

if [ "$rolecount" = "0" ]; then

	echo "INFO: Replication role not found. Creating..."

	success=false
	psql -c "CREATE ROLE ${replication_user} WITH REPLICATION PASSWORD '${replication_password}' LOGIN;" && success=true

	if ! $success ; then

		echo "ERROR: Failed to create '${replication_user}' role."
		exit 5

	fi

else

	echo "INFO: Replication role found. Ensuring password..."

	success=false
	psql -c "ALTER ROLE ${replication_user} WITH REPLICATION PASSWORD '${replication_password}' LOGIN;" && success=true

	if ! $success ; then

		echo "ERROR: Failed to set password for '${replication_user}' role."
		exit 5

	fi

fi

echo "promote - Done!"
exit 0
