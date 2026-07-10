FROM debian:bullseye
RUN apt-get update && apt-get install -y nginx openssl && rm -rf /var/lib/apt/lists/*
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx.key \
    -out /etc/ssl/certs/nginx.crt \
    -subj "/CN=galves-a.42.fr"
COPY conf/nginx.conf /etc/nginx/conf.d/
COPY tools/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
EXPOSE 443
ENTRYPOINT [ "entrypoint.sh" ]
