---
title: Testing GitHub Workflows with ACT Locally - Complete Guide
summary: Learn how to test GitHub Actions locally using ACT tool, handle secrets, debug workflows, and avoid common pitfalls on macOS M1
date: 2025-08-19
authors:
  - Mati: author.jpeg
---

## preface

Testing GitHub Actions locally is a great way to catch problems before you push code to GitHub. The [act](https://github.com/nektos/act) tool lets you run your workflows on your own Mac (M1) and see exactly what will happen. This guide explains how to install **act**, where to find your workflow files, how to list jobs, and how to test everything before publishing. All commands use the full flag names for clarity.

**ACT** is an open-source project that allows you to run GitHub Actions locally using Docker containers, saving you time and GitHub Actions minutes while developing and debugging workflows.

---

## steps

- Install **act** with Homebrew
- Find workflows in **.github/workflows/**
- List jobs with **act --list**
- Run jobs with **act --job {job-name}** or all jobs with **act**
- Use ARM64 images for M1 Macs and set architecture flags if needed
- Pass secrets and environment variables for local testing
- Test different event triggers (push, pull_request, workflow_dispatch, custom events)
- Use custom Docker images for faster builds
- Debug with verbose and dry run modes
- Use configuration file (**.actrc**) for default settings
- Know ACT limitations (no Windows/macOS runners, limited permissions, some actions may not work)
- Troubleshoot common issues (Docker, permissions, submodules, disk space)

### 1. Install act on macOS M1

Open your terminal and run:

```sh
brew install act
```

If you don’t have Homebrew, install it first from [brew.sh](https://brew.sh/).

### 2. Where are workflows located?

GitHub Actions workflows are stored in your repository under **.github/workflows/**. Each workflow is a YAML file that describes jobs and steps.

Example workflow structure:

```
.github/workflows/
├── hugo-deploy.yaml
├── ci.yaml
└── release.yaml
```

In this repository, we have a **hugo-deploy.yaml** workflow that builds and deploys a Hugo site to GitHub Pages.

### 3. List available jobs in a workflow

To see the jobs defined in your workflow files, run:

```sh
act --list
```

This will show all jobs you can run locally. Make sure you are in your repository’s root directory.

### 4. Test a workflow before publishing

To run a specific job locally, use:

```sh
act --job {job-name}
```

For example, to test the Hugo deployment workflow from this repository:

```sh
# Test the build job from hugo-deploy.yaml
act --job build

# Test with the same Ubuntu version as in the workflow
act -P ubuntu-24.04=ghcr.io/catthehacker/ubuntu:act-24.04 --job build
```

To run a specific workflow file:

```sh
# Run the Hugo deployment workflow
act --workflows .github/workflows/hugo-deploy.yaml
```

Replace **{job-name}** with the name of the job you want to test (from the previous step).

To run all jobs:

```sh
act
```

### 5. Common issues on Mac

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

### 6. Working with secrets and environment variables

ACT allows you to pass secrets and environment variables to your workflows:

#### Using secrets file

Create a **.secrets** file in your repository root:

```
GITHUB_TOKEN=your_token_here
API_KEY=your_api_key
```

Run with secrets:

```sh
act --secret-file .secrets
```

#### Passing individual secrets

```sh
act --secret GITHUB_TOKEN=your_token --secret API_KEY=your_key
```

#### Environment variables

For the Hugo workflow, you might want to test with specific Hugo environment:

```sh
act --env HUGO_ENVIRONMENT=production --env TZ=Etc/UTC --job build
```

#### Testing with workflow-specific environment variables

The Hugo deployment workflow uses these environment variables:

```sh
act --env HUGO_VERSION=0.147.7 \
    --env HUGO_ENVIRONMENT=production \
    --env HUGO_CACHEDIR=/tmp/hugo_cache \
    --job build
```

### 7. Testing different event triggers

ACT supports various GitHub event triggers:

#### Test push events

```sh
# Test push to main branch (triggers hugo-deploy.yaml)
act push

# Test push with specific branch
act --eventpath .github/events/push-main.json
```

#### Test pull request events

```sh
act pull_request
```

#### Test workflow_dispatch (manual trigger)

```sh
# Test manual workflow dispatch
act workflow_dispatch
```

#### Test specific events with custom payloads

Create custom event files in **.github/events/** directory:

**.github/events/push-main.json**:

```json
{
  "ref": "refs/heads/main",
  "repository": {
    "default_branch": "main"
  }
}
```

Then run:

```sh
act --eventpath .github/events/push-main.json
```

### 8. Advanced usage and debugging

#### Verbose output for debugging

```sh
act --verbose --job build
```

#### Dry run (show what would be executed)

```sh
act --dryrun --job build
```

#### Use specific platform images

```sh
# Use the same Ubuntu version as the Hugo workflow
act --platform ubuntu-24.04=ghcr.io/catthehacker/ubuntu:act-24.04

# Use latest Ubuntu image
act --platform ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest

# You can build your own Docker image with pre-installed dependencies for faster local runs.
docker build -t my-act-image -f Dockerfile.act .
act --platform ubuntu-24.04=my-act-image --job build
```

#### Test specific jobs from Hugo workflow

```sh
# Test only the build job
act --job build

# Test both build and deploy jobs (deploy will likely fail locally)
act --job build --job deploy
```

#### Skip jobs that don't work locally

Some jobs like **deploy** that interact with GitHub Pages won't work locally:

```sh
# Only test the build process
act --job build --workflows .github/workflows/hugo-deploy.yaml
```

### 9. Configuration file

Create **.actrc** file in your home directory or repository root for default settings:

```
# Platform configurations for this Hugo site
--platform ubuntu-24.04=ghcr.io/catthehacker/ubuntu:act-24.04
--container-architecture linux/arm64
--secret-file .secrets

# Environment variables for Hugo
--env HUGO_ENVIRONMENT=production
--env TZ=Etc/UTC

# Verbose output for debugging
--verbose
```

This configuration matches the Hugo deployment workflow requirements.

### 10. Practical example: Testing the Hugo deployment workflow

Let's test the actual **hugo-deploy.yaml** workflow from this repository:

#### Step 1: List available jobs

```sh
act --list
```

Expected output:

```
Stage  Job ID  Job name  Workflow name              Workflow file
0      build   build     Deploy Hugo site to Pages  hugo-deploy.yaml
0      deploy  deploy    Deploy Hugo site to Pages  hugo-deploy.yaml
```

#### Step 2: Test the build job

```sh
# Test build job with verbose output
act --job build --verbose \
    --platform ubuntu-24.04=ghcr.io/catthehacker/ubuntu:act-24.04 \
    --env HUGO_VERSION=0.147.7 \
    --env HUGO_ENVIRONMENT=production
```

#### Step 3: Common issues with Hugo workflow

The deploy job will fail locally because it requires GitHub Pages deployment permissions:

```sh
# This will fail locally (expected)
act --job deploy
```

**Error**: **Error: Resource not accessible by integration**

This is normal - the deploy job is meant to run only on GitHub's servers.

#### Step 4: Test workflow with custom event

Create **.github/events/push-main.json**:

```json
{
  "ref": "refs/heads/main",
  "before": "0000000000000000000000000000000000000000",
  "after": "1234567890123456789012345678901234567890",
  "repository": {
    "default_branch": "main",
    "name": "matsonkepson.github.io"
  },
  "pusher": {
    "name": "test-user"
  }
}
```

Then test:

```sh
act --eventpath .github/events/push-main.json --job build
```

### 11. Troubleshooting common issues

#### Permission denied errors

```sh
# Fix Docker socket permissions
sudo chmod 666 /var/run/docker.sock
```

#### Out of disk space

```sh
# Clean up ACT containers and images
docker system prune -a
```

#### Hugo-specific issues

**Missing submodules**:

```sh
# Make sure git submodules are initialized
git submodule update --init --recursive
```

---

## useful resources

- [ACT GitHub Repository](https://github.com/nektos/act) - Official documentation and latest releases
- [GitHub Actions Documentation](https://docs.github.com/en/actions) - Complete guide to GitHub Actions
- [Docker Images for ACT](https://github.com/catthehacker/docker_images) - Optimized Docker images for ACT
- [ACT Community Discussions](https://github.com/nektos/act/discussions) - Get help from the community
