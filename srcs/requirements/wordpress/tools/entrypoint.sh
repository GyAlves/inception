#!/bin/bash

while ! mysqladmin -h mariadb -u "$MYSQL_USER" -p"$(cat $MYSQL_PASSWORD_FILE)" ping --silent; do
    sleep 1
done

if [ ! -f "/var/www/html/wp-config.php" ]; then
    wp core download --path=/var/www/html --allow-root

    DB_PASS=$(cat "$MYSQL_PASSWORD_FILE")
    WP_ADMIN_PASS=$(cat "$WP_ADMIN_PASSWORD_FILE")
    WP_USER_PASS=$(cat "$WP_USER_PASSWORD_FILE")

    wp config create --path=/var/www/html \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$DB_PASS" \
        --dbhost="$DB_HOST:3306" \
        --allow-root

    wp core install --path=/var/www/html \
        --url="$DOMAIN_NAME" \
        --title="Inception 42SP" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASS" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --allow-root

    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --path=/var/www/html \
        --user_pass="$WP_USER_PASS" \
        --role=editor \
        --allow-root
fi

exec php-fpm8.2 -F
