# Dockerfiles Stable Optimization Design

## Goal

Optimize this Dockerfiles repository for conservative stable image maintenance, reliable local scripts, and predictable CI behavior without broad rewrites or risky upstream image swaps.

## Current Context

The repository contains a collection of Docker image directories. After removing legacy images, the active image directories are:

- `cloudflared`
- `mosdns`
- `network-tools`
- `openvpn`
- `system-tools`
- `tcping`
- `wireguard`

Top-level automation consists of:

- `Makefile` for local build, run, clean, test, and help targets.
- `build-all.sh` for discovering Dockerfiles, building images, and pushing them.
- `run.sh` for extracting commented `docker run` examples from Dockerfiles.
- `.github/workflows/docker-images.yml` for GitHub Actions matrix builds and pushes to ACR, DockerHub, and GHCR.

## Stable Image Policy

The optimization policy is conservative stable:

- Prefer official stable, LTS, or explicitly versioned image tags.
- Avoid rolling development tags such as `devel`, `sid`, `edge`, and nightly-style tags.
- Do not replace third-party images blindly when no clearly better stable upstream is identified.
- Keep explicitly versioned tool images where they already exist unless an upstream stable release is verified.
- Treat third-party `latest` tags as acceptable only when no safer tag is available in this phase, and document them for future review.

## Image Baseline Changes

First-phase image changes should be limited to high-confidence stability improvements:

- `network-tools/Dockerfile`: replace `debian:sid-slim` with a Debian stable slim tag, initially `debian:bookworm-slim`.
- `system-tools/Dockerfile`: replace `ubuntu:devel` with an Ubuntu LTS tag, initially `ubuntu:24.04`.
- `cloudflared/Dockerfile`: keep the explicit `cloudflare/cloudflared:2025.5.0` tag unless a verified stable release upgrade is intentionally made in a separate change.
- `mosdns/Dockerfile`: keep the explicit `irinesistiana/mosdns:v5.3.3` tag unless a verified stable release upgrade is intentionally made in a separate change.
- `openvpn/Dockerfile`: keep `yyxx/openvpn:latest` for this phase and mark it as a third-party latest image requiring later source review.
- `tcping/Dockerfile`: keep `pouriyajamshidi/tcping:latest` for this phase and mark it as a third-party latest image requiring later source review.
- `wireguard/Dockerfile`: keep `linuxserver/wireguard:latest` for this phase because the upstream project commonly publishes through that tag; digest pinning can be evaluated separately.

## Script Improvements

The local scripts should become safer and more predictable while preserving their current workflow.

### Makefile

The `image` target should build a single image correctly. The current target constructs an image name and context but does not invoke `build`. It should use the selected container runtime with a command equivalent to:

```bash
docker build -t "${REGISTRY}/${PROJECT}/${DIR}:${APP_VERSION}" "./${DIR}"
```

The Makefile should continue to auto-detect `podman` or `docker`.

### build-all.sh

The bulk build script should:

- Fail early with a clear error if neither `docker` nor `podman` is available.
- Fail early with a clear error if GNU `parallel` is missing.
- Use a fresh temporary errors file per run instead of a persistent `./errors` file.
- Sort discovered Dockerfile paths for deterministic behavior.
- Preserve existing build-and-push behavior unless a compatibility issue is found during implementation.

Docker and podman push flag compatibility should be handled conservatively. If `--disable-content-trust=false` is Docker-specific in practice, the script should either apply it only for Docker or omit it for podman.

### run.sh

The `run.sh` script currently extracts a commented `docker run` command from each Dockerfile and executes it with `eval`. In the first phase, this behavior should not be redesigned. The script should remain compatible with existing Dockerfile comment headers, while README documentation should clarify that this is a convenience helper for trusted repository content.

A later phase can replace comment parsing with explicit per-image metadata if needed.

## CI Improvements

The GitHub Actions workflow should remain matrix-based and continue discovering Dockerfile directories automatically.

First-phase CI improvements:

- Sort discovered Dockerfile directories before creating the matrix.
- Add pull request coverage that builds images but does not push them.
- Keep push behavior for `main`.
- Preserve existing registry targets: ACR, DockerHub, and GHCR.
- Keep deletion handling simple: removed directories naturally disappear from the discovered matrix.

Additional linting such as Hadolint is out of scope for the first phase unless requested separately.

## Documentation Improvements

`README.md` should be updated to:

- Fix the `Usase` typo to `Usage`.
- List the currently maintained image directories.
- Explain local commands for help, build all, build one image, run one image, and test.
- Document the conservative stable image policy.
- Note that some third-party images still use `latest` pending separate source review.

## Verification

Required verification for the first implementation pass:

```bash
rtk make help
rtk bash -n build-all.sh
rtk bash -n run.sh
rtk make test
```

If a container runtime is available locally, also run:

```bash
rtk make image DIR=network-tools
rtk make image DIR=system-tools
```

If local image builds require network access or registry access and fail because of environment restrictions, record the exact failure and verify syntax plus dry-run behavior instead.

## Out Of Scope

This design does not include:

- Pinning every image by digest.
- Replacing all third-party images with custom Dockerfiles.
- Adding Hadolint or other new CI dependencies.
- Redesigning `run.sh` around a new metadata format.
- Changing registry ownership, publishing credentials, or release semantics.
- Updating every upstream image to the absolute latest release.

## Risks

- `debian:bookworm-slim` may not contain package versions expected by `network-tools`; the build check must catch this.
- `ubuntu:24.04` package names may differ from `ubuntu:devel`; the build check must catch this.
- Third-party `latest` images remain a maintenance risk, but replacing them without source review would be higher risk in this phase.
- Podman compatibility for push flags may need runtime-specific handling.
