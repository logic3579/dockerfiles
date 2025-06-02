## dockerfiles

[![Build and Push Container Images](https://github.com/logic3579/dockerfiles/actions/workflows/docker-images.yml/badge.svg)](https://github.com/logic3579/dockerfiles/actions/workflows/docker-images.yml)

This is a repo to hold various Dockerfiles for images.


## Usase

### Using `Makefile`

```
$ make help
all                            Build all and push.
build                          Builds all the dockerfiles in the repository.
clean                          Cleaning up.
image                          Build a Dockerfile (ex. DIR=network-tools).
run                            Run a Dockerfile from the command at the top of the file (ex. DIR=system-tools).
test                           Run the tests.
```
