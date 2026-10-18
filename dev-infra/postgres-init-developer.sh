#!/bin/sh
# Crea (o actualiza) el rol DEV_USER con la contraseña DEV_PASSWORD.
# Se ejecuta solo la primera vez que se inicializa el volumen.
set -eu

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
  -v dev_user="$DEV_USER" -v dev_password="$DEV_PASSWORD" <<'SQL'
SELECT format('CREATE ROLE %I WITH LOGIN SUPERUSER PASSWORD %L', :'dev_user', :'dev_password')
WHERE NOT EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = :'dev_user') \gexec
SELECT format('ALTER ROLE %I WITH LOGIN SUPERUSER PASSWORD %L', :'dev_user', :'dev_password') \gexec
SQL
