## dockerfiles

[![make test](https://img.shields.io/badge/Build_Status-passing-brightgrey.svg?logo=github)](https://github.com/yakir3/gitbook/actions)

This is a repo to hold various Dockerfiles for images.


**Table of Contents**

<!-- toc -->

- [Resources](#resources)
  * [Using the `Makefile`](#using-the-makefile)

<!-- tocstop -->

## Resources
### Using the `Makefile`

```
$ make help
all                            Build all and push
build                          Builds all the dockerfiles in the repository.
image                          Build a Dockerfile (ex. DIR=telnet).
run                            Run a Dockerfile from the command at the top of the file (ex. DIR=curl).
test                           Run the tests
```

> Fork from: https://github.com/jessfraz/dockerfiles
