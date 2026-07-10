# User Documentation

How to operate the Inception stack day-to-day.

---

## Start and stop

From the project root:

| Action | Command |
|---|---|
| Build and start everything in the background | `make` (alias of `make all`) |
| Stop the containers (keep volumes/images) | `make down` |
| Rebuild from scratch and restart | `make re` |
| Stop and remove containers, volumes, images, networks | `make clean` |

`make` is non-destructive: re-running it picks up image changes and recreates only the containers that need it. Stack state survives reboots if the Docker daemon is set to start on boot.

---

## Access the website

1. Make sure `galves-a.42.fr` resolves to `127.0.0.1`. On the VM, this is configured in `/etc/hosts`.
2. Open `https://galves-a.42.fr` in a browser.
3. The certificate is self-signed, so the browser will warn — accept the warning to continue.

WordPress admin panel: `https://galves-a.42.fr/wp-admin`.

---

## Credentials

Two WordPress accounts are created the first time the stack boots:

| Role | Username | Source of password |
|---|---|---|
| Administrator | `galves` | `secrets/credentials.txt` |
| Editor | `editor` | `secrets/wp_user_password.txt` |

Database credentials:

| Account | Username | Source of password |
|---|---|---|
| WordPress DB user | `wpuser` | `secrets/db_password.txt` |
| MariaDB root | `root` | `secrets/db_root_password.txt` |

### Rotating a password

1. Edit the relevant file in `secrets/`.
2. Update the live account: for WordPress users use `wp user update <user> --user_pass=...` inside the `wordpress` container; for the DB user use `ALTER USER ... IDENTIFIED BY '...'` inside the `mariadb` container.
3. The secret file is re-read by the entrypoint only on first init, so changing the file alone is not enough — the live account must also be updated.

Never commit the `secrets/` directory; it is in `.gitignore`.

---

## Check that services are running

```
docker ps
```

You should see three containers: `nginx`, `wordpress`, `mariadb` — all `Up`.

Per-service health and logs:

| Check | Command |
|---|---|
| Logs (live) for one service | `docker logs -f <nginx|wordpress|mariadb>` |
| Open a shell in a container | `docker exec -it <service> bash` |
| Verify HTTPS endpoint | `curl -kI https://galves-a.42.fr` |
| Verify WP-DB connectivity | `docker exec wordpress wp db check --allow-root --path=/var/www/html` |
| MariaDB ping | `docker exec mariadb mysqladmin ping -uroot -p"$(cat secrets/db_root_password.txt)"` |

If a container is restarting in a loop, `docker logs <name>` is the first place to look. The compose file uses `restart: unless-stopped`, so a crashed container will come back up on its own; if it keeps crashing, the logs will show why.
