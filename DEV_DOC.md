# Developer Documentation

How to set up, build, and modify the Inception stack.

---

## Setup from scratch

Target environment: a Debian or Alpine VM (the project is tested on Debian).

1. Install Docker and Docker Compose plugin, and `make`:
   ```
   sudo apt update
   sudo apt install -y docker.io docker-compose-plugin make
   sudo usermod -aG docker $USER
   newgrp docker
   ```
2. Clone the repository into the home directory.
3. Add the project domain to `/etc/hosts`:
   ```
   echo "127.0.0.1 galves-a.42.fr" | sudo tee -a /etc/hosts
   ```
4. Create the bind-mount directories required by the volumes (the compose file expects them to exist):
   ```
   sudo mkdir -p /home/galves-a/data/mariadb /home/galves-a/data/wordpress
   ```
5. Populate `secrets/` with one password per file:
   - `secrets/db_root_password.txt` — MariaDB root password
   - `secrets/db_password.txt` — password for the WordPress DB user
   - `secrets/credentials.txt` — WordPress admin password
   - `secrets/wp_user_password.txt` — WordPress editor password

   Each file must contain exactly one line, no trailing whitespace, no newline preferred.
6. Review `srcs/.env` for the non-sensitive config (domain, DB name, usernames, emails).

---

## Build and launch with the Makefile

| Target | Behaviour |
|---|---|
| `make` / `make all` | `docker compose -f srcs/docker-compose.yml up -d --build` — builds any missing/stale images and starts the stack detached |
| `make down` | `docker compose ... down` — stops and removes containers; keeps volumes and images |
| `make re` | `make down` then `make all` |
| `make clean` | `docker compose ... down -v --rmi all --remove-orphans` — full teardown including named volumes and images |

The Makefile only forwards to Docker Compose; there is no project-specific build step. The compose file lives at `srcs/docker-compose.yml` and is the source of truth for service wiring.

---

## Project layout

```
.
├── Makefile
├── secrets/                       (gitignored)
├── srcs/
│   ├── .env                       (gitignored)
│   ├── docker-compose.yml
│   └── requirements/
│       ├── mariadb/   Dockerfile + conf/50-server.cnf + tools/entrypoint.sh
│       ├── wordpress/ Dockerfile + conf/www.conf      + tools/entrypoint.sh
│       └── nginx/     Dockerfile + conf/nginx.conf    + tools/entrypoint.sh
```

Each service is fully self-contained inside its `requirements/<service>` directory: image build, daemon config, entrypoint. Modifying a service should not require touching another's directory.

---

## Modifying a service

Typical change loop:

1. Edit the Dockerfile, conf file, or entrypoint under `srcs/requirements/<service>/`.
2. `make re` to rebuild and restart everything, or for a single service:
   ```
   docker compose -f srcs/docker-compose.yml up -d --build <service>
   ```
3. Tail logs while testing:
   ```
   docker logs -f <service>
   ```

Entrypoint scripts run on every container start. Anything that should happen only on first init must be guarded with an existence check (the mariadb script gates init on `/var/lib/mysql/mysql`; the wordpress script gates on `/var/www/html/wp-config.php`). All daemons are launched with `exec` so they replace the shell and run as PID 1 — do not break this.

---

## Managing containers and volumes

| Task | Command |
|---|---|
| List running containers | `docker ps` |
| List all containers (incl. stopped) | `docker ps -a` |
| Restart one service | `docker compose -f srcs/docker-compose.yml restart <service>` |
| Open a shell inside a container | `docker exec -it <service> bash` |
| List volumes | `docker volume ls` |
| Inspect a volume | `docker volume inspect srcs_db_data` |
| Remove a single volume (data loss) | `docker volume rm srcs_db_data` |
| Inspect the network | `docker network inspect srcs_inception` |

Volume names are prefixed with the compose project name (`srcs_`) because the compose file lives in `srcs/`.

---

## Data persistence

Two named volumes, both bind-mounted to host directories:

| Volume | Host path | Container path | Owner |
|---|---|---|---|
| `db_data` | `/home/galves-a/data/mariadb` | `/var/lib/mysql` (mariadb) | MariaDB datadir |
| `wp_data` | `/home/galves-a/data/wordpress` | `/var/www/html` (wordpress and nginx) | WordPress files |

Implications:

- The data **survives** `make down` and `make re` because those do not delete volumes.
- The data **is wiped** by `make clean` (`docker compose down -v`) because that removes the named volumes — but the host directories remain (only their contents are removed by the volume removal).
- A fresh init re-runs only if the marker file is absent: deleting `wp-config.php` from `wp_data` will cause WordPress to re-bootstrap on next start; truncating `db_data` will cause MariaDB to re-initialise.
- The `wp_data` volume is mounted into **both** the wordpress and nginx containers so NGINX can serve static files directly while PHP requests are proxied to PHP-FPM on port 9000.

### Backup and restore

Backup (host-side): `tar -C /home/galves-a/data -czf backup.tgz mariadb wordpress`.
Restore: stop the stack (`make down`), extract the archive into `/home/galves-a/data/`, restart (`make`).

---

## Anti-patterns to avoid

These are explicitly forbidden by the subject and enforced by review:

- `tail -f`, `sleep infinity`, `while true`, `bash` as the entrypoint of a service container.
- `network: host`, `--link`, `links:` in compose.
- `latest` tag on any `FROM`.
- Hardcoded passwords in Dockerfiles or committed to git.
- Running daemons in the background inside a container without `exec`-ing into a foreground process.
- Publishing ports other than 443 to the host.
