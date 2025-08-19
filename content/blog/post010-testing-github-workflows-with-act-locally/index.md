---
title: testing GitHub workflows with ACT locally
summary: Click for more ...
date: 2025-08-19
authors:
  - Mati: author.jpeg
---

## preface

Testing GitHub Actions locally is a great way to catch problems before you push code to GitHub. The `act` tool lets you run your workflows on your own Mac (M1) and see exactly what will happen. This guide explains how to install `act`, where to find your workflow files, how to list jobs, and how to test everything before publishing. All commands use the full flag names for clarity.

---

## steps

- Install **act** with Homebrew
- Workflows are in **.github/workflows/**
- List jobs with **act --list**
- Run jobs with **act --job <job-name>**
- Use ARM64 images for M1 Macs

### 1. Install act on macOS M1

Open your terminal and run:

```sh
brew install act
```

If you don’t have Homebrew, install it first from [brew.sh](https://brew.sh/).

### 2. Where are workflows located?

GitHub Actions workflows are stored in your repository under **.github/workflows/**. Each workflow is a YAML file that describes jobs and steps.

Example:

```
.github/workflows/<job>.yaml
```

### 3. List available jobs in a workflow

To see the jobs defined in your workflow files, run:

```sh
act --list
```

This will show all jobs you can run locally. Make sure you are in your repository’s root directory.

### 4. Test a workflow before publishing

To run a specific job locally, use:

```sh
act --job <job-name>
```

If you want to run it with custom docker image:

```sh
act -P ubuntu-24.04=ghcr.io/catthehacker/ubuntu:act-24.04 --job build
```

Replace **<job-name>** with the name of the job you want to test (from the previous step).

To run all jobs:

```sh
act
```

### 5. Common issues on Mac M1

- If you see errors about Docker images, use the ARM64 architecture flag:

  ```sh
  act --container-architecture linux/arm64
  ```

- Make sure Docker Desktop is running before you start testing.

- If you are using colima for your local docker environment you can provision it with another arch
  ```sh
  colima status
  colima start --arch x86_64 --vm-type=vz
  ```
