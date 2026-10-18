#!/bin/sh
# Crea (o actualiza) el usuario DEV_USER con la contraseña DEV_PASSWORD.
# Se ejecuta solo la primera vez que se inicializa el volumen.
set -eu

mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<SQL
CREATE USER IF NOT EXISTS '${DEV_USER}'@'%' IDENTIFIED BY '${DEV_PASSWORD}';
ALTER USER '${DEV_USER}'@'%' IDENTIFIED BY '${DEV_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO '${DEV_USER}'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL
