---
title: Deploy ArgoCD with Helm or Terraform
summary: Deploying ArgoCD on a local Kubernetes cluster using Terraform or Helm.
date: 2024-11-08
authors:
  - Mati: author.jpeg
---

### preface

Experiment with using Terraform to set up ArgoCD. Start by creating the necessary files. Then, initialize your Terraform
configuration with **terraform init**, and apply the configuration using **terraform apply**.
Application will be created inside argoCD namespace, to get the secret run

```bash
k -n argocd get secrets argocd-initial-admin-secret \
-o jsonpath="{.data.password}"|base64 -d ;echo
```

to access the application with port forward run

```bash
k -n argocd port-forward svc/argocd-server 8080:80
```

website: [http://127.0.0.1:8080](http://127.0.0.1:8080)

username : admin

password: token from previous secret

### terraform code

provider.tf

```terraform
terraform {
  required_version = ">= 1.9"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

## tryout for AWS cluster
# provider "helm" {
#   kubernetes {
#     host                   = aws_eks_cluster.demo.endpoint
#     cluster_ca_certificate = base64decode(aws_eks_cluster.demo.certificate_authority[0].data)
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.demo.id]
#       command     = "aws"
#     }
#   }
# }

```

argocd.tf

```terraform
resource "helm_release" "argocd" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "7.7.0"
  timeout          = 600

  values = [file("config/argocd.yaml")]
}
```

config/argocd.yaml

```yaml
# Disable HTTPS; expose it via ingress and terminate TLS there
configs:
  params:
    server.insecure: true

notifications:
  enabled: true
  secret:
    create: false
```

### bonus

Install argoCD manually with helm

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd --namespace argocd --create-namespace \
--version 7.7.0 --values config/argocd.yaml argo/argo-cd
```
