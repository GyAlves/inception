
## Overview

System administration project using Docker. Set up a small infrastructure composed of different services inside a virtual machine using `docker compose`. Each service runs in its own container, built from custom Dockerfiles based on Alpine or Debian (penultimate stable version).

---

## Architecture

```
WWW (port 443, HTTPS)
        |
   [ NGINX ] ---- TLSv1.2 / TLSv1.3
        |
   port 9000
        |
  [ WordPress + PHP-FPM ]
        |
   port 3306
        |
   [ MariaDB ]
```

- **NGINX**: sole entrypoint, port 443 only, TLS termination
- **WordPress + PHP-FPM**: application layer, no nginx inside
- **MariaDB**: database layer, no nginx inside
- **Docker network**: connects all containers
- **Volume 1**: WordPress database (`/home/<login>/data`)
- **Volume 2**: WordPress website files (`/home/<login>/data`)

---

## Directory Structure

```
.
├── Makefile
├── secrets/
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
├── srcs/
│   ├── docker-compose.yml
│   ├── .env
│   └── requirements/
│       ├── mariadb/
│       │   ├── Dockerfile
│       │   ├── .dockerignore
│       │   ├── conf/
│       │   └── tools/
│       ├── nginx/
│       │   ├── Dockerfile
│       │   ├── .dockerignore
│       │   ├── conf/
│       │   └── tools/
│       └── wordpress/
│           ├── Dockerfile
│           ├── .dockerignore
│           ├── conf/
│           └── tools/
├── README.md
├── USER_DOC.md
└── DEV_DOC.md
```

---

## Implementation Guide

### Phase 1 - Environment Setup

- [ ] Set up a Virtual Machine (Debian or Alpine-based)
- [ ] Install Docker and Docker Compose on the VM
- [ ] Create the project directory structure as shown above
- [ ] Configure `/etc/hosts` so `<login>.42.fr` points to `127.0.0.1`
- [ ] Create the `Makefile` at root that builds everything via `docker-compose.yml`
- [ ] Create the `.env` file inside `srcs/` with all environment variables (DOMAIN_NAME, MYSQL_USER, etc.)
- [ ] Create the `secrets/` directory with credential files and add them to `.gitignore`

### Phase 2 - MariaDB Container

- [ ] Write the Dockerfile based on penultimate stable Alpine or Debian (no `latest` tag)
- [ ] Install MariaDB server
- [ ] Create an entrypoint script that:
  - Initializes the database if not already initialized
  - Creates the WordPress database
  - Creates a regular user and sets passwords from environment variables/secrets
  - Starts `mysqld` as PID 1 (foreground, no hacky patches)
- [ ] Configure MariaDB to listen on port 3306
- [ ] Test: connect to the database from another container

### Phase 3 - WordPress + PHP-FPM Container

- [ ] Write the Dockerfile based on penultimate stable Alpine or Debian
- [ ] Install PHP-FPM and required PHP extensions for WordPress
- [ ] Download and install WordPress via WP-CLI
- [ ] Create an entrypoint script that:
  - Configures `wp-config.php` with database credentials from env/secrets
  - Creates two WordPress users (one admin, one regular)
  - Admin username must NOT contain "admin/Admin/administrator/Administrator" etc.
  - Starts `php-fpm` in foreground as PID 1
- [ ] Configure PHP-FPM to listen on port 9000
- [ ] Test: verify WordPress connects to MariaDB

### Phase 4 - NGINX Container

- [ ] Write the Dockerfile based on penultimate stable Alpine or Debian
- [ ] Install NGINX
- [ ] Generate or provide TLS/SSL certificates (self-signed is fine)
- [ ] Configure NGINX to:
  - Listen on port 443 only (HTTPS)
  - Use TLSv1.2 or TLSv1.3 only
  - Proxy PHP requests to WordPress container on port 9000
  - Serve the domain `<login>.42.fr`
- [ ] Start NGINX in foreground as PID 1
- [ ] Test: access `https://<login>.42.fr` in the browser

### Phase 5 - Docker Compose & Networking

- [ ] Write `docker-compose.yml` with all three services
- [ ] Define the docker network (no `network: host`, no `--link`, no `links:`)
- [ ] Define two named volumes (database and WordPress files) mapped to `/home/<login>/data`
- [ ] Set restart policy for all containers (`restart: on-failure` or `restart: unless-stopped`)
- [ ] Reference `.env` file for environment variables
- [ ] Use Docker secrets for sensitive data (recommended)
- [ ] Ensure Docker image names match service names
- [ ] Ensure Dockerfiles are called in `docker-compose.yml`

### Phase 6 - Makefile

- [ ] `make` / `make all`: build and start the infrastructure
- [ ] `make down`: stop containers
- [ ] `make re`: rebuild everything
- [ ] `make clean`: stop and remove containers, volumes, networks

### Phase 7 - Documentation

- [ ] `README.md` with:
  - Italicized first line: *This project has been created as part of the 42 curriculum by `<login>`*
  - Description section (explain Docker usage, design choices)
  - Comparisons: VMs vs Docker, Secrets vs Env Vars, Docker Network vs Host Network, Docker Volumes vs Bind Mounts
  - Instructions section
  - Resources section (including AI usage description)
- [ ] `USER_DOC.md`: how to start/stop, access website and admin panel, manage credentials, check services
- [ ] `DEV_DOC.md`: setup from scratch, build/launch with Makefile, manage containers/volumes, data persistence

### Phase 8 - Security & Validation Checklist

- [ ] No passwords hardcoded in Dockerfiles
- [ ] No credentials committed to git (use `.gitignore`)
- [ ] No `latest` tag in any Dockerfile
- [ ] No `tail -f`, `bash`, `sleep infinity`, `while true` in entrypoints
- [ ] No `network: host`, `--link`, or `links:` in docker-compose
- [ ] All containers use PID 1 properly (daemon runs in foreground)
- [ ] NGINX is the only entrypoint (port 443)
- [ ] TLSv1.2 or TLSv1.3 only
- [ ] `.env` file stores environment variables
- [ ] Docker secrets used for confidential data
- [ ] Containers auto-restart on crash
- [ ] Volumes at `/home/<login>/data`

---

## Bonus Part

Only evaluated if mandatory is perfect.

- [ ] Redis cache for WordPress
- [ ] FTP server pointing to WordPress volume
- [ ] Static website (any language except PHP)
- [ ] Adminer (database management UI)
- [ ] A service of your choice (must justify during defense)

Each bonus service needs its own Dockerfile, container, and optionally its own volume.

---

## Study & Code Roadmap

| Phase | What to Code | What to Study |
|-------|-------------|---------------|
| 1 | Environment Setup (VM, directory structure, Makefile skeleton, `.env`, secrets) | Docker Fundamentals, Virtual Machines, Makefile |
| 2 | MariaDB Container (Dockerfile, entrypoint script, config) | MariaDB, PID 1 and Process Management, Shell Scripting |
| 3 | WordPress + PHP-FPM Container (Dockerfile, entrypoint, WP-CLI setup) | WordPress + PHP-FPM, Shell Scripting, Security (secrets vs env vars) |
| 4 | NGINX Container (Dockerfile, TLS certs, reverse proxy config) | NGINX, TLS/SSL (TLSv1.2 vs TLSv1.3), Security (certificates) |
| 5 | Docker Compose & Networking (services, network, volumes) | Docker Compose, Networking, Volumes and Data Persistence |
| 6 | Makefile (all targets: `make`, `make down`, `make re`, `make clean`) | Makefile (deep dive into targets and recipes) |
| 7 | Documentation (README.md, USER_DOC.md, DEV_DOC.md) | Review all topics — writing docs forces you to solidify understanding |
| 8 | Security & Validation Checklist | Security (full review), Docker Fundamentals (revisit anti-patterns) |

**How to use this table**: before starting each phase, read the study topics listed for it. Then implement the phase. If you get stuck, go back to the study material — the topics are matched so the theory directly supports the code you're writing.

---

## Topics to Study

### Docker Fundamentals
- What is a container vs a virtual machine
- Docker images, layers, and caching
- Dockerfile instructions (`FROM`, `RUN`, `COPY`, `EXPOSE`, `ENTRYPOINT`, `CMD`)
- Difference between `ENTRYPOINT` and `CMD`
- Multi-stage builds
- `.dockerignore` files
- Why you should not use the `latest` tag

### Docker Compose
- `docker-compose.yml` syntax and structure
- Service definitions, dependencies (`depends_on`)
- Named volumes and bind mounts
- Network definitions and service discovery (DNS by service name)
- Environment variables and `.env` files
- Restart policies (`no`, `always`, `on-failure`, `unless-stopped`)
- Build context and Dockerfile path

### PID 1 and Process Management
- What is PID 1 in a container and why it matters
- Signal handling (SIGTERM, SIGKILL) in containers
- Why `tail -f` and `sleep infinity` are anti-patterns
- Running daemons in foreground mode (`nginx -g 'daemon off;'`, `mysqld`, `php-fpm -F`)
- Proper entrypoint script design (exec to replace shell with daemon)

### NGINX
- NGINX as a reverse proxy
- TLS/SSL configuration (certificates, protocols, ciphers)
- TLSv1.2 vs TLSv1.3
- Self-signed certificates with `openssl`
- FastCGI proxy to PHP-FPM (`fastcgi_pass`)
- Server blocks and location directives

### MariaDB
- MariaDB installation and initialization
- Database and user creation via SQL or `mysql_install_db`
- Configuration files (`my.cnf` / `mariadb-server.cnf`)
- Running `mysqld` in foreground
- Securing the installation (root password, remote access)

### WordPress + PHP-FPM
- WordPress installation and `wp-config.php`
- WP-CLI for automated setup (download, install, user creation)
- PHP-FPM configuration (`www.conf`, listen address)
- PHP-FPM pool settings and running in foreground (`-F` flag)
- Required PHP extensions for WordPress (`mysqli`, `pdo`, `gd`, etc.)

### Networking
- Docker bridge networks
- Container DNS resolution (service name as hostname)
- Why `network: host` and `--link` are discouraged/forbidden
- Port mapping and exposing ports
- How containers communicate internally vs externally

### Volumes and Data Persistence
- Named volumes vs bind mounts
- Volume drivers and mount points
- Data persistence across container restarts
- Volume ownership and permissions

### Security
- Docker secrets: what they are and how to use them
- Environment variables vs secrets (trade-offs)
- `.gitignore` for credentials
- TLS certificate management
- Principle of least privilege in containers

### Shell Scripting (for entrypoints)
- Bash/sh scripting basics for entrypoint scripts
- `exec` command (replacing shell process with daemon)
- Conditional initialization (check if DB already exists)
- `envsubst` or `sed` for template configuration files

### Virtual Machines
- Setting up a VM (VirtualBox, UTM, etc.)
- Port forwarding and networking in VMs
- `/etc/hosts` configuration
- File sharing between host and VM

### Makefile
- Makefile targets and recipes
- Calling `docker compose` from Make
- Phony targets

