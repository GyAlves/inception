FROM debian:bullseye
RUN apt-get update && apt-get install -y mariadb-server mariadb-client && rm -rf /var/lib/apt/lists/*
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/
COPY tools/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
EXPOSE 3306
ENTRYPOINT [ "entrypoint.sh" ]
