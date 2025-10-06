#!/bin/bash
set -ex

# Create required directories and fix permissions
mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld /var/lib/mysql

# Read secrets
ROOT_PASSWORD=$(cat /run/secrets/db_root_pass)
USER_PASSWORD=$(cat /run/secrets/db_pass)

# Only initialize if DB is not already present
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # Start MariaDB w/o networking for setup
    mysqld_safe --user=mysql --datadir=/var/lib/mysql --skip-networking &
    MYSQL_PID=$!

    # Wait for MariaDB to be ready
    for i in {30..0}; do
        if mysqladmin ping --silent; then
            break
        fi
        sleep 1
    done
    if [ "$i" = 0 ]; then
        echo >&2 "MariaDB failed to start for initialization."
        exit 1
    fi

    # Do initial setup using the password from secret
    mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${USER_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${ROOT_PASSWORD}' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

    # Stop MariaDB after setup
    mysqladmin -u root -p"${ROOT_PASSWORD}" shutdown
fi

# Start MariaDB normally
exec mysqld --user=mysql
