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

Print registry and runtime settings:

```bash
make info
```
