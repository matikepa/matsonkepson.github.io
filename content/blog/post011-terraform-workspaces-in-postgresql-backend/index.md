---
title: Terraform Workspaces in PostgreSQL Backend
summary: Terraform configuration that creates an S3 bucket and uses PostgreSQL as the backend storage.
date: 2025-10-07
authors:

  - Mati: author.jpeg

---

## Project Structure

---
```yaml
terraform-postgres-project/
│
├── environments/
│   ├── dev.tfvars
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
      version = "~> 4.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.21"
    }
  }

  backend "pg" {
    conn_str = "postgres://terraform:terraformpassword@localhost:5432/terraform_state?sslmode=disable"
  }
}

provider "aws" {
  region = var.region
}

provider "postgresql" {
  host     = "localhost"
  port     = 5432
  database = "terraform_state"
  username = "terraform"
  password = "terraformpassword"
  sslmode  = "disable"
}
```

## s3.tf

```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-bucket-${var.environment}"
  
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
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

```
## docker-compose.yml
```yaml
services:
  postgres:
    image: postgres:17
    environment:
      POSTGRES_DB: terraform_state
      POSTGRES_USER: terraform
      POSTGRES_PASSWORD: terraformpassword
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:

```

## Setup and initialization

```bash
# Start PostgreSQL container
docker-compose up -d

# Initialize Terraform
terraform init

# Create S3 Bucket and Configure State Backend
terraform workspace new dev
terraform apply -var="environment=dev"

# Switch between environments
terraform workspace select stage
terraform apply -var="environment=stage"

terraform workspace select prod
terraform apply -var="environment=prod"
```

## Key Considerations

- State Security: The PostgreSQL backend stores state securely
- Multi-Environment Support: Uses Terraform workspaces for different environments
- Local PostgreSQL Backend: Easily manageable with Docker Compose