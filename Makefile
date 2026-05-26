APP_VERSION := $(shell git rev-parse --short HEAD)
CONTAINER_COMMAND := $(shell command -v podman 2> /dev/null || command -v docker 2> /dev/null || command -v container 2> /dev/null || echo "none")
CONTAINER_RUNTIME := $(notdir $(CONTAINER_COMMAND))
FORCE_FLAG := $(if $(filter container,$(CONTAINER_RUNTIME)),,--force)
REGISTRY ?= docker.io
PROJECT ?= logic3579
image_ref = $(REGISTRY)/$(PROJECT)/$(subst /,:,$(patsubst %/,%,$(DIR))):$(APP_VERSION)

check_dir = $(if $(DIR),,$(error DIR is required, e.g. DIR=network-tools))
check_container = $(if $(filter none,$(CONTAINER_COMMAND)), \
				  $(error Command <podman>, <docker> or <container> not found!))

.DEFAULT_GOAL := help
.PHONY: all build clean image run info help

all: build  ## Build and push all images.

build:  ## Builds all the Dockerfiles in the repository.
	@echo "Building all images"
	@$(CURDIR)/build-all.sh

clean:  ## Clean up images. Pass DIR=<dir> to also remove that image.
	@echo "Cleaning up"
	$(call check_container)
	${CONTAINER_COMMAND} image prune $(FORCE_FLAG) || true
	$(if $(DIR),${CONTAINER_COMMAND} image rm $(image_ref) $(FORCE_FLAG) || true)

image:  ## Build a Dockerfile (ex. DIR=network-tools).
	@echo "Build an image"
	$(call check_dir)
	$(call check_container)
	$(CONTAINER_COMMAND) build -f ./$(DIR)/Dockerfile -t $(image_ref) ./$(DIR)

run:  ## Run a Dockerfile from the command at the top of the file (ex. DIR=network-tools).
	@echo "Run container"
	$(call check_dir)
	@$(CURDIR)/run.sh $(DIR)

info:  ## Print registry and project settings.
	@echo "REGISTRY=$(REGISTRY)"
	@echo "PROJECT=$(PROJECT)"
	@echo "CONTAINER_RUNTIME=$(CONTAINER_RUNTIME)"

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
