---
title: Fix "docker pull" certificate signed by unknown authority
summary: Step-by-step solutions to resolve Docker's "certificate signed by unknown authority" error when pulling from a local repository.
date: 2024-12-03
authors:
  - Mati: author.jpeg
---

## preface

---

To use a local repository with Docker, you need to create the repository first. Docker relies on certificates during
this process, and if the local repository's certificates aren't trusted, Docker will produce an error about the
untrusted repository. This occurs because Docker doesn't recognize the self-signed certificates of your local repository
as trustworthy. To fix this, you need to ensure that the certificates used by your local repository are properly
configured and trusted by Docker. This might involve adding the certificate to Docker's trusted certificate list or
correctly setting up the repository's SSL configuration. Doing this will prevent the untrusted repository error and
facilitate smooth interaction between Docker and your local repository.

> This post originates from my highest-rated [answer](https://stackoverflow.com/a/55260438/7786358) on Stack Overflow.

---

## steps

There are two main in my opinion possible solutions which can help you

### First solution, works without demon restart

1. first create an empty json file

```bash
cat << _EOF > /etc/docker/daemon.json
{ }
_EOF
```

2. than run the following to add certs

```bash

export registry_address="local.repo.com" # adjust to your needs
export registry_port="5000"              # adjust to your needs

openssl s_client -showcerts -connect ${registry_address}:${registry_port} < /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /etc/docker/certs.d/${registry_address}/ca.crt
```

### Second solution, importing certificate to system

1. save the certificate to the file
   - :exclamation: the port is crucial, no need for the protocol :exclamation:

```bash
export registry_address="local.repo.com" # adjust to your needs
export registry_port="5000"              # adjust to your needs

openssl s_client -showcerts -connect ${registry_address}:${registry_port} < /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ca.crt
```

2. copy extracted certificate to /usr/local/share/ca-certificates/

```bash
sudo cp ca.crt /usr/local/share/ca-certificates/
```

3. update system-wide certificates

```bash
sudo update-ca-certificates
```

4. restart docker !

```bash
sudo systemctl restart docker

# or for non-systemd environments

sudo service docker restart

```
