#!/usr/bin/env bash

PG_LOG=/vagrant/tmp/log/pgsql.log

. ${BASH_DIR}util.sh

(

display Create test db

# Create db
cat << EOF | su - postgres -c psql
-- Create the database user:
CREATE USER $PGUSER WITH PASSWORD '$PGPASSWORD';

-- Create the database:
CREATE DATABASE $PGDATABASE WITH OWNER $PGUSER;

-- auto explain for analyse all queries and inside functions
LOAD 'auto_explain';
SET auto_explain.log_min_duration = 0;
SET auto_explain.log_analyze = true;
EOF

exit 0
) 2>&1 | tee $PG_LOG
