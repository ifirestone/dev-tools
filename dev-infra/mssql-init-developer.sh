#!/bin/bash
set -e

SQLCMD=(/opt/mssql-tools18/bin/sqlcmd -C -S mssql -U sa -P "$MSSQL_SA_PASSWORD")

for i in $(seq 1 30); do
  if "${SQLCMD[@]}" -Q "SELECT 1" >/dev/null 2>&1; then
    break
  fi
  echo "Waiting for mssql to accept connections... ($i/30)"
  sleep 2
done

"${SQLCMD[@]}" -i /mssql-init-developer.sql -v DEV_USER="$DEV_USER" DEV_PASSWORD="$DEV_PASSWORD"

echo "Login [$DEV_USER] ready with sysadmin role and database [$DEV_USER]."
