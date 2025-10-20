#!/bin/bash
set -ex

# Read secrets
DB_PASS=$(cat /run/secrets/db_pass)

echo "Starting WordPress initialization..."
echo "DB_HOST=$DB_HOST"
echo "DB_USER=$DB_USER" 
echo "DB_NAME=$DB_NAME"

# Check if WordPress is installed, if not download it
if [ ! -f wp-config-sample.php ]; then
    echo "WordPress files not found. Downloading WordPress..."
    curl -o wordpress.tar.gz https://wordpress.org/latest.tar.gz
    tar -xzf wordpress.tar.gz --strip-components=1
    rm wordpress.tar.gz
    echo "✅ WordPress downloaded and extracted to persistent volume"
else
    echo "✅ WordPress files already exist in persistent volume"
fi

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
until mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -e "SELECT 1;" >/dev/null 2>&1; do
  echo "MariaDB not ready yet, retrying in 3 seconds..."
  sleep 3
done

echo "✅ MariaDB connection successful!"

# Create wp-config.php if it doesn't exist
if [ ! -f wp-config.php ]; then
    echo "Creating wp-config.php..."
    cp wp-config-sample.php wp-config.php
    
    # Replace database configuration placeholders
    sed -i "s/database_name_here/$DB_NAME/" wp-config.php
    sed -i "s/username_here/$DB_USER/" wp-config.php
    sed -i "s/password_here/$DB_PASS/" wp-config.php
    sed -i "s/localhost/$DB_HOST/" wp-config.php
    
    echo "✅ wp-config.php created successfully"
else
    echo "✅ wp-config.php already exists"
fi

# Set correct permissions
echo "Setting file permissions..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo "🚀 Starting PHP-FPM..."
exec php-fpm8.2 -F
