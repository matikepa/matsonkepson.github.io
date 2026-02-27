---
title: 'Step into n8n automation: local setup with Docker Compose'
description: 'Run n8n workflow automation locally using Docker Compose with PostgreSQL and pgAdmin. Quick hands-on guide.'
date: 2026-02-25
author: 'Mati'
tags:
  - n8n
  - Docker Compose
  - Automation
  - PostgreSQL
categories:
  - DevOps
lightgallery: true
---

## Preface

---

[n8n](https://n8n.io/) is an open-source workflow automation tool. Think of it as a self-hosted alternative
to Zapier where you connect services together visually, and n8n runs the workflows for you.

In this post I will show you how to spin up n8n on your laptop using Docker Compose.
The setup includes three containers:

- **n8n** — the automation engine itself
- **PostgreSQL** — a database where n8n stores its data
- **pgAdmin** — a web UI so you can peek into the database when needed

By the end you will have a working n8n instance at `http://localhost:5678`.

---

## Start the stack with Docker Compose

Create a `docker-compose.yml` file (or save it wherever you like) and paste the content below.
Then run one command to bring everything up:

```bash
# Using Docker
docker compose up -d

# Or using Podman
podman compose up -d
```

### docker-compose.yml

Please unfold the working example of docker compose file below.

```yaml
services:
  n8n:
    image: n8nio/n8n:stable
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=secret
      - N8N_RUNNERS_ENABLED=true
      - N8N_BLOCK_ENV_ACCESS_IN_NODE=false
      - N8N_GIT_NODE_DISABLE_BARE_REPOS=true
      - NODE_OPTIONS=--no-deprecation
      - N8N_SECURE_COOKIE=false
      - N8N_HOST=localhost
      - N8N_RUNNERS_PYTHON_ENABLED=true
    ports: ['5678:5678']
    volumes:
      - n8n_data:/home/node/.n8n
    networks:
      - n8n_network
  postgres:
    image: postgres:18.1
    environment:
      - POSTGRES_DB=n8n
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=secret
    volumes:
      - n8n_postgres_data:/var/lib/postgresql
      # Uncomment the line below to expose PostgreSQL to external connections.
      # - ./init-postgres.sh:/docker-entrypoint-initdb.d/init-postgres.sh
    # ports: ["5432:5432"]  # uncomment to expose PostgreSQL on the host
    networks:
      - n8n_network
  pgadmin:
    image: dpage/pgadmin4:9.12
    container_name: pgadmin4
    environment:
      PGADMIN_DEFAULT_EMAIL: 'admin@local.host'
      PGADMIN_DEFAULT_PASSWORD: 'admin'
    ports:
      - 5050:80
    volumes:
      - n8n_pgadmin_data:/var/lib/pgadmin
    depends_on:
      - postgres
    networks:
      - n8n_network
volumes:
  n8n_data:
  n8n_postgres_data:
  n8n_pgadmin_data:
networks:
  n8n_network:
```

Once the containers are running, open these URLs in your browser:

| Service | URL                                            | Credentials                  |
| ------- | ---------------------------------------------- | ---------------------------- |
| n8n     | [http://localhost:5678](http://localhost:5678) | `please register`            |
| pgAdmin | [http://localhost:5050](http://localhost:5050) | `admin@local.host` / `admin` |

---

## Optional: allow external connections to PostgreSQL

By default PostgreSQL only accepts connections from inside the Docker network.
If you need to connect from your host machine or another tool, create a file
called `init-postgres.sh` next to your `docker-compose.yml` and paste the content below.
Then uncomment the volume mount line in the `postgres` service above and recreate the container.
PostgreSQL will run this script on first start — it opens up the config so the database
listens on all network interfaces and accepts connections from any IP.

> **Warning:** This is fine for local development but **never** do this in production.

```bash
#!/bin/bash
postgresql_conf="/var/lib/postgresql/data/postgresql.conf"
pghba_conf="/var/lib/postgresql/data/pg_hba.conf"

# Listen on all addresses instead of just localhost
sed -i "s|^#*listen_addresses[[:space:]]*=.*|listen_addresses = '*'|" $postgresql_conf

# Allow connections from any IPv4 / IPv6 address
sed -i "s|127.0.0.1/32|0.0.0.0/0|g" $pghba_conf
sed -i "s|::1/128|::/0|g" $pghba_conf

cat <<EOL >>$pghba_conf
# Allow all IPv4 connections
host    all             all             0.0.0.0/0               md5
# Allow all IPv6 connections
host    all             all             ::1/128                md5
EOL

# Restart PostgreSQL to pick up the changes
pg_ctl -D /var/lib/postgresql/data -m fast restart
echo "Done! PostgreSQL now accepts external connections."
```

---

## Summary

That is all you need. With a single `docker compose up` you get a fully working n8n environment
backed by PostgreSQL, plus pgAdmin for database inspection. From here you can start building
workflows, connect APIs, and automate repetitive tasks — all running on your own machine.
