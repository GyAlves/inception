*This project has been created as part of the 42 curriculum by `gyasminalves`*

# Inception

System administration project: a small infrastructure of three services orchestrated with Docker Compose, each built from a custom Dockerfile and isolated in its own container.

---

## Description

The infrastructure exposes a single HTTPS entrypoint (NGINX) that proxies PHP requests over a private Docker network to a WordPress + PHP-FPM container, which itself talks to a MariaDB container. All persistent data lives on the host under `/home/gyasminalves/data`, mounted into the containers via named volumes.

Design choices:

- **One process per container.** Each Dockerfile starts a single daemon (`mysqld`, `php-fpm`, `nginx`) as PID 1 in the foreground, so signals propagate correctly and the container dies when the daemon dies.
- **No `latest` tag.** Every image is pinned to `debian:bullseye` (penultimate stable).
- **Secrets, not env vars, for credentials.** Passwords are mounted at `/run/secrets/*` and read inside entrypoint scripts; non-sensitive config (DB name, usernames, domain) lives in `srcs/.env`.
- **Private bridge network.** Containers reach each other by service name (`mariadb`, `wordpress`); only NGINX publishes a port (443) to the host.
- **Bind-mounted named volumes.** The two volumes (`db_data`, `wp_data`) use `driver_opts` to bind directly to `/home/gyasminalves/data/{mariadb,wordpress}`, so the data is visible and backupable from the host.

---

## Comparisons

### VMs vs Docker
A VM virtualises the whole machine: its own kernel, full OS, virtual hardware. It is heavyweight (gigabytes, slow boot) but offers strong isolation. A Docker container shares the host kernel and isolates only the userspace (filesystem, network, processes) through namespaces and cgroups. It is lightweight (megabytes, sub-second start) but weaker on isolation. For reproducible service deployment, Docker wins on speed and density; for running a different OS or untrusted code, a VM is safer.

### Secrets vs Env Vars
Environment variables are convenient but leak easily: they appear in `docker inspect`, in `/proc/<pid>/environ`, in child processes, and often in logs. Docker secrets are mounted as in-memory files at `/run/secrets/<name>`, readable only by the service that declared them and never persisted to the image. In this project, database and WordPress passwords are secrets; the database name, admin username, and domain are env vars because they are not sensitive.

### Docker Network vs Host Network
With the default bridge or a user-defined bridge, each container gets its own network namespace and IP, and inter-container traffic is isolated from the host. With `network: host`, the container shares the host's network stack directly: any port the container opens is the host's port, and there is no isolation. Host networking is faster but breaks port mapping, breaks multi-container co-existence on the same port, and is explicitly forbidden by the subject. This project uses a user-defined bridge (`inception`) so service discovery works via DNS (service name = hostname).

### Docker Volumes vs Bind Mounts
A pure named volume is fully managed by Docker (stored under `/var/lib/docker/volumes`), portable, and the right default for opaque data. A bind mount points a container path at an arbitrary host path: cheap, transparent, but couples the container to the host layout. This project uses named volumes with `driver_opts: type=none, o=bind, device=...` — the volumes are declared and managed like named volumes (so `make clean` removes them) but their backing store is the host directory required by the subject (`/home/<login>/data`).

---

## Instructions

Prerequisites: Docker, Docker Compose, `make`. On the VM, add `127.0.0.1 gyasminalves.42.fr` to `/etc/hosts`, and create the bind-mount directories:

```
sudo mkdir -p /home/gyasminalves/data/mariadb /home/gyasminalves/data/wordpress
```

Build and start everything:

```
make
```

Then open `https://gyasminalves.42.fr` in a browser (accept the self-signed certificate warning). The WordPress admin panel is at `https://gyasminalves.42.fr/wp-admin`.

Other targets: `make down` (stop), `make re` (rebuild), `make clean` (stop and wipe containers/volumes/images).

See `USER_DOC.md` for day-to-day usage and `DEV_DOC.md` for development.

---

## Resources

- Docker docs — https://docs.docker.com
- Docker Compose reference — https://docs.docker.com/compose/compose-file/
- MariaDB documentation — https://mariadb.com/kb/en/documentation/
- WordPress + WP-CLI — https://wp-cli.org
- NGINX documentation — https://nginx.org/en/docs/
- 42 Inception subject

### AI usage

Claude (Anthropic) was used as a pair-programming assistant for explanations of Docker internals (PID 1, bind-mounted named volumes, secrets vs env vars), for reviewing the `docker-compose.yml` against the subject's anti-patterns, and for drafting these documentation files. All produced code and configuration were read, validated, and adjusted before being committed.
