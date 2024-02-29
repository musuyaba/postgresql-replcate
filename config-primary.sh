#!/bin/sh
set -e

# Configure PostgreSQL to use SCRAM-SHA-256 authentication for local connections
echo "local all all scram-sha-256" >> "$PGDATA/pg_hba.conf"

# Allow replication connections from any host, using MD5 authentication
echo "host replication all 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"

# Setting the authentication method for host connections:
echo "host all all 0.0.0.0/0 scram-sha-256" >> "$PGDATA/pg_hba.conf"

# Optional: Reload PostgreSQL configuration without restarting the service
pg_ctl reload

# Initialize the database and create a new PostgreSQL database cluster
# initdb

# Start PostgreSQL in the background with the specific configurations
postgres -c wal_level=replica -c hot_standby=on -c max_wal_senders=10 -c max_replication_slots=10 -c hot_standby_feedback=on &

# Wait for the PostgreSQL server to start
until pg_isready -U "${POSTGRES_USER}" --dbname="${POSTGRES_DB}"; do
  echo "Waiting for PostgreSQL to become available..."
  sleep 1
done

pg_ctl reload

# Execute SQL commands with environment variable values
psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
    CREATE USER ${REPLICA_USER} WITH REPLICATION LOGIN ENCRYPTED PASSWORD '${REPLICA_PASS}';
    SELECT pg_create_physical_replication_slot('replication_slot');
EOSQL

# Keep the PostgreSQL server process in the foreground to prevent the container from exiting
wait