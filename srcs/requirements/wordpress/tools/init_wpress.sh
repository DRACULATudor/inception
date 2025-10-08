#!/bin/bash
set -ex


#add to compose secrets
DB_PASS=$(cat /run/secrets/db_pass)


#wait for mariadb to ping it s finisehd initalising
until mysqladmin ping -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" --silent; do
  echo "Waiting for MariaDB..."
  sleep 2
done

#in case config hasn't been added
#we copy it and add the fill the placeholders with the req vars
if [ ! -f wp-config.php ]; then
    cp wp-config-sample.php wp-config.php
    sed -i "s/database_name_here/$DB_NAME/" wp-config.php
    sed -i "s/username_here/$DB_USER/" wp-config.php
    sed -i "s/password_here/$DB_PASS/" wp-config.php
    sed -i "s/localhost/$DB_HOST/" wp-config.php
fi

#change ownership perms
chown -R www-data:www-data /var/www/html


#no need for dameno since we want to keep pid 1 runnign
exec php-fpm8.2 -F
