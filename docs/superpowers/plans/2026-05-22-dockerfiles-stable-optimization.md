# Dockerfiles Stable Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the approved conservative stable optimization for the Dockerfiles repository.

**Architecture:** Keep the repository as a simple Dockerfile collection. Make targeted changes to image base tags, local build scripts, CI discovery behavior, and README documentation without introducing new metadata formats or broad rewrites.

**Tech Stack:** Dockerfiles, GNU Make, Bash, GitHub Actions, Docker/Podman.

---

## File Structure

- Modify `network-tools/Dockerfile`: replace rolling Debian `sid` base with stable Debian slim.
- Modify `system-tools/Dockerfile`: replace Ubuntu `devel` base with Ubuntu LTS.
- Modify `Makefile`: fix the single-image build target and keep runtime auto-detection.
- Modify `build-all.sh`: add dependency checks, deterministic Dockerfile discovery, fresh error file handling, and runtime-aware push options.
- Modify `.github/workflows/docker-images.yml`: add PR trigger and deterministic directory matrix.
- Modify `README.md`: document current image set, stable policy, and local commands.
- No new runtime code modules are required.

## Task 1: Stabilize Base Images

**Files:**
- Modify: `network-tools/Dockerfile`
- Modify: `system-tools/Dockerfile`

- [ ] **Step 1: Update `network-tools` base image**

Change:

```dockerfile
FROM debian:sid-slim
```

to:

```dockerfile
FROM debian:bookworm-slim
```

- [ ] **Step 2: Update `system-tools` base image**

Change:

```dockerfile
FROM ubuntu:devel
```

to:

```dockerfile
FROM ubuntu:24.04
```

- [ ] **Step 3: Verify Dockerfile references**

Run:

```bash
rtk rg -n 'debian:sid-slim|ubuntu:devel' network-tools system-tools
```

Expected: no matches and exit code `1`.

- [ ] **Step 4: Commit**

```bash
git add network-tools/Dockerfile system-tools/Dockerfile
git commit -m "chore: use stable base images"
```

## Task 2: Fix Single Image Build Target

**Files:**
- Modify: `Makefile`

- [ ] **Step 1: Inspect current `image` target**

Run:

```bash
rtk sed -n '1,180p' Makefile
```

Expected: `image` target currently checks `DIR` but does not call `build`.

- [ ] **Step 2: Update `image` target**

Replace the current command under `image:` with:

```make
	$(CONTAINER_COMMAND) build -t $(REGISTRY)/$(PROJECT)/$(subst /,:,$(patsubst %/,%,$(DIR))):$(APP_VERSION) ./$(DIR)
```

Keep the existing `DIR` validation line.

- [ ] **Step 3: Verify Makefile help still renders**

Run:

```bash
rtk make help
```

Expected: output includes `image                          Build a Dockerfile (ex. DIR=network-tools).`

- [ ] **Step 4: Verify test target**

Run:

```bash
rtk make test
```

Expected: command exits `0` and prints the configured `REGISTRY` and `PROJECT`.

- [ ] **Step 5: Commit**

```bash
git add Makefile
git commit -m "fix: build single Docker image from Makefile"
```

## Task 3: Harden Bulk Build Script

**Files:**
- Modify: `build-all.sh`

- [ ] **Step 1: Replace runtime discovery with explicit checks**

Near the top of `build-all.sh`, replace:

```bash
CONTAINER_CMD=$(command -v docker || command -v podman)
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
REPO_URL="${REPO_URL:-docker.io/logic3579}"
JOBS=${JOBS:-2}

ERRORS="$(pwd)/errors"
```

with:

```bash
if command -v docker >/dev/null 2>&1; then
        CONTAINER_CMD=$(command -v docker)
        CONTAINER_RUNTIME=docker
elif command -v podman >/dev/null 2>&1; then
        CONTAINER_CMD=$(command -v podman)
        CONTAINER_RUNTIME=podman
else
        echo "ERROR: docker or podman is required." >&2
        exit 1
fi

if ! command -v parallel >/dev/null 2>&1; then
        echo "ERROR: GNU parallel is required." >&2
        exit 1
fi

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
REPO_URL="${REPO_URL:-docker.io/logic3579}"
JOBS=${JOBS:-2}
ERRORS=$(mktemp)
trap 'rm -f "$ERRORS"' EXIT
```

- [ ] **Step 2: Add runtime-aware push helper**

Add this function before `build_and_push()`:

```bash
push_image(){
        image=$1

        if [[ "$CONTAINER_RUNTIME" == "docker" ]]; then
                "${CONTAINER_CMD}" push --disable-content-trust=false "$image"
        else
                "${CONTAINER_CMD}" push "$image"
        fi
}
```

- [ ] **Step 3: Use push helper**

Replace both direct push commands:

```bash
"${CONTAINER_CMD}" push --disable-content-trust=false "${REPO_URL}/${base}:${suite}" && break
```

and:

```bash
"${CONTAINER_CMD}" push --disable-content-trust=false "${REPO_URL}/${base}:latest"
```

with:

```bash
push_image "${REPO_URL}/${base}:${suite}" && break
```

and:

```bash
push_image "${REPO_URL}/${base}:latest"
```

- [ ] **Step 4: Make Dockerfile discovery deterministic**

Keep the existing discovery shape, but ensure the command remains:

```bash
mapfile -t files < <(find -L . -iname '*Dockerfile' | sed 's|./||' | sort)
```

- [ ] **Step 5: Verify shell syntax**

Run:

```bash
rtk bash -n build-all.sh
```

Expected: exit code `0`.

- [ ] **Step 6: Commit**

```bash
git add build-all.sh
git commit -m "chore: harden bulk image build script"
```

## Task 4: Improve CI Matrix Behavior

**Files:**
- Modify: `.github/workflows/docker-images.yml`

- [ ] **Step 1: Add pull request trigger**

Update the top trigger block to:

```yaml
on:
  push:
    branches:
      - main
  pull_request:
```

- [ ] **Step 2: Sort discovered Docker directories**

In `Find Docker directories`, replace:

```bash
dirs=$(find . -name Dockerfile -exec dirname {} \; | sed 's|^./||' | jq -R -s -c 'split("\n") | map(select(. != ""))')
```

with:

```bash
dirs=$(find . -name Dockerfile -exec dirname {} \; | sed 's|^./||' | sort | jq -R -s -c 'split("\n") | map(select(. != ""))')
```

- [ ] **Step 3: Verify workflow YAML is readable**

Run:

```bash
rtk sed -n '1,220p' .github/workflows/docker-images.yml
```

Expected: file shows both `push` and `pull_request`, and the discovery command includes `sort`.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/docker-images.yml
git commit -m "ci: build Docker images on pull requests"
```

## Task 5: Refresh README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace README content**

Use this content:

```markdown
## dockerfiles

[![Build and Push Container Images](https://github.com/logic3579/dockerfiles/actions/workflows/docker-images.yml/badge.svg)](https://github.com/logic3579/dockerfiles/actions/workflows/docker-images.yml)

This repository holds Dockerfiles for small utility and networking images.

## Images

- `cloudflared`
- `mosdns`
- `network-tools`
- `openvpn`
- `system-tools`
- `tcping`
- `wireguard`

## Version policy

Images follow a conservative stable policy:

- Prefer official stable, LTS, or explicitly versioned tags.
- Avoid rolling development tags such as `devel`, `sid`, `edge`, and nightly-style tags.
- Keep third-party `latest` tags only when a safer stable tag has not been selected yet.

## Usage

```bash
make help
```

Build and push all images:

```bash
make build
```

Build one image:

```bash
make image DIR=network-tools
```

Run one image using the `docker run` example from the Dockerfile header:

```bash
make run DIR=system-tools
```

Run the lightweight test target:

```bash
make test
```
```

- [ ] **Step 2: Verify typo is gone**

Run:

```bash
rtk rg -n 'Usase|Usage|Version policy' README.md
```

Expected: output includes `Usage` and `Version policy`, and does not include `Usase`.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: document stable image policy"
```

## Task 6: Final Verification

**Files:**
- Verify repository state.

- [ ] **Step 1: Run required syntax and Makefile checks**

Run:

```bash
rtk make help
rtk bash -n build-all.sh
rtk bash -n run.sh
rtk make test
```

Expected: all commands exit `0`.

- [ ] **Step 2: Check active Dockerfile directories**

Run:

```bash
rtk find . -maxdepth 2 -name Dockerfile
```

Expected: output contains only active image directories:

```text
./cloudflared/Dockerfile
./mosdns/Dockerfile
./network-tools/Dockerfile
./openvpn/Dockerfile
./system-tools/Dockerfile
./tcping/Dockerfile
./wireguard/Dockerfile
```

- [ ] **Step 3: Build stable base image targets if runtime and network allow**

Run:

```bash
rtk make image DIR=network-tools
rtk make image DIR=system-tools
```

Expected: both image builds exit `0`.

If the builds fail because Docker/Podman is unavailable or network access is blocked, record the exact error and do not claim build success.

- [ ] **Step 4: Review git status**

Run:

```bash
rtk git status --short
```

Expected: status shows only intended tracked changes plus pre-existing untracked `.agents/` and `plugins/` if they were not committed separately.

- [ ] **Step 5: Commit verification-only adjustments if needed**

If verification requires small fixes, commit them:

```bash
git add Makefile build-all.sh README.md .github/workflows/docker-images.yml network-tools/Dockerfile system-tools/Dockerfile
git commit -m "chore: finalize stable Dockerfile optimization"
```

If no fixes are needed, do not create an empty commit.
