#!/bin/bash

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --datadir=/var/lib/mysql --user=mysql
    mysqld --user=mysql &

    while ! mysqladmin ping --silent; do
        sleep 1
    done

    DB_PASS=$(cat "$MYSQL_PASSWORD_FILE")
    DB_ROOT_PASS=$(cat "$MYSQL_ROOT_PASSWORD_FILE")

    mysql -u root <<EOF
        CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;
        CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$DB_PASS';
        GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
        ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASS';
        FLUSH PRIVILEGES;
EOF

    mysqladmin -u root -p"$DB_ROOT_PASS" shutdown
fi

exec mysqld --user=mysql
