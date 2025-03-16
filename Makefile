MAINTAINER = yakir3
APP_NAME := livestream-exporter
APP_VERSION := $(shell git rev-parse --short HEAD)
APP_PORT ?= 8080
CONTAINER_COMMAND := $(shell command -v podman 2> /dev/null || command -v docker 2> /dev/null || echo "none")
REGISTRY ?= docker.io
PROJECT ?= project
IMAGE_NAME = ${REGISTRY}/${PROJECT}/${APP_NAME}:${APP_VERSION}

# pcheck container runtime
ifeq ($(CONTAINER_COMMAND),none)
    $(error "Command <podman> or <docker> not found!")
endif

check_defined = $(strip $(foreach 1,$1, \
				$(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = $(if $(value $1),, \
				  $(error Undefined $1$(if $2, ($2))$(if $(value @), \
				  required by target '$@')))

.PHONY: all test build image clean run
all: build clean  ## Build all and push.


build:  ## Builds all the dockerfiles in the repository.
	@echo "Building all image"
	@$(CURDIR)/build-all.sh

clean:  ## Cleaning up.
	@echo "Cleaning up"
	${CONTAINER_COMMAND} image prune --force || true;\
	${CONTAINER_COMMAND} rmi ${CONTAINER_IMAGE} --force || true

image:  ## Build a Dockerfile (ex. DIR=network-tools).
	@echo "Build a image"
	@:$(call check_defined, DIR, directory of the Dockefile)
	$(CONTAINER_COMMAND) $(REGISTRY)/$(subst /,:,$(patsubst %/,%,$(DIR))):$(APP_VERSION) ./$(DIR)

run:  ## Run a Dockerfile from the command at the top of the file (ex. DIR=system-tools).
	@echo "Run cantainer"
	@:$(call check_defined, DIR, directory of the Dockefile)
	@$(CURDIR)/run.sh $(DIR)

test:  ## Run the tests.
	@echo "Testing..."
	@echo $(REGISTRY)
	@echo $(PROJECT)

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'