#!/usr/bin/env bash

PG_LOG=/vagrant/tmp/log/pgsql.log

. ${BASH_DIR}util.sh

(
display Installing PostgreSQL

[[ -z "$PGUSER" ]] && { echo "!!! PostgreSQL username not set. Check the Vagrant file."; exit 1; }
[[ -z "$PGPASSWORD" ]] && { echo "!!! PostgreSQL password not set. Check the Vagrant file."; exit 1; }

# Set some variables
PGVERSION=${PGVERSION:-9.5}

# Add PostgreSQL Apt repository
# to get latest stable
PG_REPO_APT_SOURCE=/etc/apt/sources.list.d/pgdg.list
if [ ! -f "$PG_REPO_APT_SOURCE" ]
then
	display Adding repos for postgres
	echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > "$PG_REPO_APT_SOURCE"

	# Add PGDG repo key:
	wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | sudo apt-key add -
fi

# Update Apt repos
sudo apt-get update

# Install PostgreSQL
# -qq implies -y --force-yes
#sudo apt-get install -qq "postgresql-$PGVERSION" "postgresql-contrib-$PGVERSION"

# Install dev version of postgresql to support debugging
apt-get -qq install "postgresql-server-dev-$PGVERSION" "postgresql-contrib-$PGVERSION"

# Configure PostgreSQL
# Listen for localhost connections
PG_CONF="/etc/postgresql/$PGVERSION/main/postgresql.conf"
PG_HBA="/etc/postgresql/$PGVERSION/main/pg_hba.conf"

# Edit postgresql.conf to change listen address to '*':
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"

# Edit postgresql.conf to change port:
if [ ! -z "$PGPORT" ]
then
	display Setting postgres server port to $PGPORT
	sed -i "/port = /c\port = $PGPORT" "$PG_CONF"
fi

# Append to pg_hba.conf to add password auth:
echo "host    all             all             all                     md5" >> "$PG_HBA"

# We need to add password oauth for $DBUSER before other aouth configs.
match='# "local" is for Unix domain socket connections only'
insert="local    all             $PGUSER                           md5"
sed -i "s/$match/$match\n$insert/" $PG_HBA

# Restart so that all new config is loaded:
service postgresql restart

cat << EOF | su - postgres -c psql
-- Change pg super pass:
ALTER USER postgres WITH PASSWORD '$PG_SUPERPASS';

-- Create role for replication
CREATE ROLE $PG_REPUSER WITH REPLICATION PASSWORD '$PG_REPPASS' LOGIN;
EOF

# allow postgres to execute commands as replication user
sudo mkdir -p /var/lib/postgresql
sudo echo "*:*:*:$PG_REPUSER:$PG_REPPASS" >> /var/lib/postgresql/.pgpass
sudo chown postgres:postgres /var/lib/postgresql/.pgpass
sudo chmod 0600 /var/lib/postgresql/.pgpass

# Restart PostgreSQL for good measure
service postgresql restart

exit 0
) 2>&1 | tee $PG_LOG
