#!/bin/bash
set -e

# Essential: Create socket directories FIRST with correct permissions
mkdir -p /var/run/mysqld /run/mysqld
chown -R mysql:mysql /var/run/mysqld /run/mysqld /var/lib/mysql
chmod 755 /var/run/mysqld /run/mysqld

# Read secrets (your exact variables)
ROOT_PASSWORD=$(cat /run/secrets/db_root_pass)
REG_USER_PASSWORD=$(cat /run/secrets/db_pass)
SUPER_USER_PASSWORD=$(cat /run/secrets/wp_admin_pass)

# Debug: Print your environment variables
echo "MYSQL_DATABASE=$MYSQL_DATABASE"
echo "MYSQL_SUPER_USER=$MYSQL_SUPER_USER"
echo "MYSQL_REGULAR_USER=$MYSQL_REGULAR_USER"
echo "ROOT_PASSWORD=$ROOT_PASSWORD"
echo "SUPER_USER_PASSWORD=$SUPER_USER_PASSWORD"
echo "REG_USER_PASSWORD=$REG_USER_PASSWORD"

# MariaDB configuration for all interfaces
cat <<EOF > /etc/mysql/mariadb.conf.d/50-server.cnf
[mysqld]
user = mysql
bind-address = 0.0.0.0
socket = /var/run/mysqld/mysqld.sock
pid-file = /var/run/mysqld/mysqld.pid

[client]
socket = /var/run/mysqld/mysqld.sock
host = localhost
EOF

# Initialize database only if it doesn't exist
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB database..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql --rpm > /dev/null

    # Start MariaDB in safe mode for initialization
    echo "Starting MariaDB for initialization..."
    mysqld_safe --user=mysql --datadir=/var/lib/mysql --skip-networking --socket=/var/run/mysqld/mysqld.sock &
    pid="$!"

    # Wait for socket file to exist
    echo "Waiting for socket file..."
    for i in {60..0}; do
        if [ -S /var/run/mysqld/mysqld.sock ]; then
            echo "Socket file exists!"
            break
        fi
        sleep 1
    done

    if [ "$i" = 0 ]; then
        echo >&2 "Socket file not created."
        exit 1
    fi

    # Wait for MariaDB to be ready via socket
    echo "Waiting for MariaDB socket connection..."
    for i in {60..0}; do
        if mysqladmin --socket=/var/run/mysqld/mysqld.sock --protocol=socket ping --silent 2>/dev/null; then
            echo "MariaDB socket ready!"
            break
        fi
        sleep 1
    done

    if [ "$i" = 0 ]; then
        echo >&2 "MariaDB failed to start for initialization."
        exit 1
    fi

    # Setup database and users - FORCE socket connection
    echo "Setting up database and users..."
    mysql --socket=/var/run/mysqld/mysqld.sock --protocol=socket --host=localhost <<EOSQL
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${ROOT_PASSWORD}');
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_SUPER_USER}'@'%' IDENTIFIED BY '${SUPER_USER_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_SUPER_USER}'@'%';
CREATE USER IF NOT EXISTS '${MYSQL_REGULAR_USER}'@'%' IDENTIFIED BY '${REG_USER_PASSWORD}';
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_REGULAR_USER}'@'%';
FLUSH PRIVILEGES;
EOSQL

    echo "Database initialization complete. Shutting down..."
    # Shutdown initialization MariaDB
    mysqladmin --socket=/var/run/mysqld/mysqld.sock --protocol=socket -u root -p"${ROOT_PASSWORD}" shutdown

    # Wait for process to exit
    for i in {30..0}; do
        if ! ps -p $pid > /dev/null 2>&1; then
            echo "MariaDB initialization process stopped."
            break
        fi
        sleep 1
    done
fi

echo "Starting MariaDB server..."
# Start MariaDB normally with networking enabled
exec mysqld --user=mysql --socket=/var/run/mysqld/mysqld.sock
