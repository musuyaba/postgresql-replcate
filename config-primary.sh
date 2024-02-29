#!/bin/sh
set -e

# Wait for the PostgreSQL server to start
until pg_isready -U "${POSTGRES_USER}" --dbname="${POSTGRES_DB}"; do
  echo "Waiting for PostgreSQL to become available..."
  sleep 1
done

# Execute SQL commands with environment variable values
psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
    CREATE USER ${REPLICA_USER} WITH REPLICATION LOGIN ENCRYPTED PASSWORD '${REPLICA_PASS}';
    SELECT pg_create_physical_replication_slot('replication_slot');
EOSQL
