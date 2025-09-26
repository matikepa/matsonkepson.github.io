---
title: Run Minikube on Docker
summary: Step-by-step instructions to install and run Minikube locally using Docker.
date: 2024-11-06
authors:
  - Mati: author.jpeg
---

### preface

While there are other options like Kind, K3s, MicroK8s, the Minikube is a balance of simplicity, flexibility,
additionally community support makes it a great choice for many developers. What's more ist really super simple to start
with. To stat, all you need to have is installed docker engine and kubectl cli locally!

### install minikube

```bash
wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
## Optional
echo "alias m='/usr/local/bin/minikube '" >> ~/.bash_aliases
echo "source <(minikube completion bash)" >> ~/.bashrc
```

start your minikube

```bash
minikube start --kubernetes-version=v1.31.0 \
--addons metrics-server --driver=docker
```

add more nodes

```bash
minikube node add
```

get basic web interface for kubernetes

```bash
minikube dashboard
```
