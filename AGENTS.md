# AGENTS.md

@/Users/logic/.codex/RTK.md

## Project Notes

- This repository maintains Dockerfiles for utility and networking images.
- Prefer stable, lightweight base images for debug containers.
- Use Alpine stable tags for compact debug images when package coverage is sufficient.
- Do not include unrelated generated files or local secrets in commits.

## Container Runtimes

- `Makefile`, `build-all.sh`, and `run.sh` detect runtimes in order: docker → podman → Apple `container` (macOS, `/usr/local/bin/container`).
- Apple `container` differs from docker/podman in CLI shape; the scripts dispatch by runtime name:
  - Image ops are nested: use `image push`/`image tag`/`image rm` (no top-level aliases like `rmi`).
  - No `--force` flag on `image prune` / `image rm`.
  - No `--rm` / `--force-rm` flags on `build`.
  - `build` defaults Dockerfile path to PWD (not the context dir), so the Makefile passes explicit `-f ./$(DIR)/Dockerfile`.
  - Cannot allocate a pty when stdin isn't a terminal (e.g. under `make`); `run.sh` strips `-it`/`-i`/`-t` from the extracted command when this runtime is active.
- `RUN_ARCH=amd64 make run DIR=...` overrides the architecture on Apple `container` (which otherwise defaults to host arch). Use it when a published image isn't multi-arch yet.

## Dockerfile Header Convention

- Each Dockerfile starts with a `# docker run ...` example block. The block **must** end with a lone `#` line.
- `run.sh` extracts the block via `sed -n '/docker run/,/^#$/p'`; without the terminator the range matches through end-of-file and the eval'd command becomes garbage.

## Makefile Targets

- `make image DIR=<dir>` builds a single image tagged `$(REGISTRY)/$(PROJECT)/<dir>:<short_sha>`.
- `make clean` always prunes; `make clean DIR=<dir>` additionally removes the SHA-tagged image.
- `make run DIR=<dir>` extracts and runs the Dockerfile header's example via `run.sh`.
- `make info` prints `REGISTRY` / `PROJECT` / detected `CONTAINER_RUNTIME`.
- Default goal is `help`.

## CI

- `.github/workflows/docker-images.yml` builds and pushes to ACR, DockerHub, and ghcr.io.
- Multi-arch: `linux/amd64,linux/arm64` by default (via `setup-qemu-action` + `build-push-action` `platforms:`). Per-directory overrides live in the `Determine build platforms` step — e.g. `tcping` is amd64-only because its upstream base image (`pouriyajamshidi/tcping`) isn't published multi-arch.
- Tags pushed per image: `:<short_sha>` and `:latest`.
- Pull requests build but do not push.
