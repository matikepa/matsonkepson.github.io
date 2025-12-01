---
title: Terraform Workspaces in PostgreSQL Backend
summary: Terraform configuration that creates an S3 bucket and uses PostgreSQL as the backend storage.
date: 2025-10-07
authors:
  - Mati: author.jpeg
---

This blog post explores how to set up Terraform workspaces with a PostgreSQL backend to manage infrastructure across multiple environments (develop, stage, prod). Rather than relying on AWS S3 for state storage, we'll use PostgreSQL running in Docker, providing a lightweight local alternative that simplifies development workflows.

You'll learn how to configure Terraform providers for AWS and PostgreSQL, create some example boilerplate code, and manage different deployment environments using workspaces. This setup is ideal for teams looking to practice infrastructure-as-code principles with flexible state management while maintaining secure, versioned state files while having terraform enterprise experience.

---

## Project Structure

```yaml
terraform-postgres-project/
│
├── environments/
│   ├── develop.tfvars
│   ├── stage.tfvars
│   └── prod.tfvars
├── main.tf
├── s3.tf
├── variables.tf
├── outputs.tf
└── docker-compose.yml
```

---

## main.tf

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.21"
    }
  }

  backend "pg" {
    conn_str = "postgres://postgres:postgres@localhost:5432/postgres?sslmode=disable"
  }
}

provider "aws" {
  region = var.region
}

provider "postgresql" {
  host     = "localhost"
  port     = 5432
  database = "postgres"
  username = "postgres"
  password = "postgres"
  sslmode  = "disable"
}
```

## s3.tf

```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-example-tf-bucket-12345x90-${var.environment}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

```

## variables.tf

```hcl
variable "region" {
  description = "AWS Region"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "develop"
}

```

## init-postgres.sh

```bash
#!/bin/bash
# Ensure PostgreSQL configuration is updated
postgresql_conf="/var/lib/postgresql/data/postgresql.conf"
pghba_conf="/var/lib/postgresql/data/pg_hba.conf"

# Update postgresql.conf to listen on all addresses
sed -i "s|^#*listen_addresses[[:space:]]*=.*|listen_addresses = '*'|" $postgresql_conf

# Update pg_hba.conf to allow connections from all IPs
sed -i "s|127.0.0.1/32|0.0.0.0/0|g" $pghba_conf
sed -i "s|::1/128|::/0|g" $pghba_conf

cat <<EOL >> $pghba_conf
# Allow all IPv4 connections
host    all             all             0.0.0.0/0               md5
# Allow all IPv6 connections
host    all             all             ::1/128                md5
EOL

# Restart PostgreSQL service to apply changes
pg_ctl -D /var/lib/postgresql/data -m fast restart

```

## compose.yml

```yaml
services:
  postgres:
    image: postgres:17
    environment:
      POSTGRES_DB: postgres
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - 5432:5432
    volumes:
      - ./init-postgres.sh:/docker-entrypoint-initdb.d/init-postgres.sh
      - postgres_data:/var/lib/postgresql/data
    networks:
      - pgadmin-network

  pgadmin:
    image: dpage/pgadmin4
    container_name: pgadmin4
    environment:
      PGADMIN_DEFAULT_EMAIL: 'admin@local.host'
      PGADMIN_DEFAULT_PASSWORD: 'admin'
    ports:
      - 5050:80
    volumes:
      - pgadmin_data:/var/lib/pgadmin
    depends_on:
      - postgres
    networks:
      - pgadmin-network

networks:
  pgadmin-network:
    driver: bridge

volumes:
  postgres_data:
  pgadmin_data:
```

## Setup and initialization

```bash
# Start PostgreSQL container
docker-compose up -d
# alternatively
podman-compose -f compose.yaml up

# Initialize Terraform
terraform init

# Create S3 Bucket and Configure State Backend
terraform workspace new develop
terraform workspace select develop
terraform plan
terraform apply -var="environment=devevlop"

# Switch between environments
terraform workspace select stage
terraform apply -var="environment=stage"

terraform workspace select prod
terraform apply -var="environment=prod"
```

## Check inside the pgAdmin

- Navigate to [http://localhost:5050/browser/](http://localhost:5050/browser/)
- Login with credentials from compose.yaml file
- Right Click at the database and select "Query Tool"
- Try below ![screen](images/pg_admin_screen.png)

## Key Considerations

- State Security: The PostgreSQL backend stores state securely
- Multi-Environment Support: Uses Terraform workspaces for different environments
- Local PostgreSQL Backend: Easily manageable with Docker Compose
