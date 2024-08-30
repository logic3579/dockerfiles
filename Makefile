# main variable
MAINTAINER = yakir
SHELL := /bin/bash
#GIT_COMMIT := $(shell git rev-parse --short HEAD)

# container variable
CONTAINER_CMD := $(shell command -v docker || command -v podman)
ifneq ($(CONTAINER_CMD),)
	CONTAINER_CMD := $(CONTAINER_CMD)
else
	CONTAINER_CMD := ""
endif
CONTAINER_BUILD=$(CONTAINER_CMD) build --rm --force-rm -t
CONTAINER_PRUNE=$(CONTAINER_CMD) image prune --force
CONTAINER_RMI=$(CONTAINER_CMD) rmi ${LOCAL_IMAGE_NAME} && $(CONTAINER_CMD) rmi ${CONTAINERHUB_IMAGE_NAME}
CONTAINER_TAG=$(CONTAINER_CMD) tag
CONTAINER_PUSH=$(CONTAINER_CMD) push


.PHONY: precondition
precondition:
	@echo "##### preconditon check step start #####"
	@$(CURDIR)/pre.sh "$(CONTAINER_CMD)"
	@echo "##### preconditon check step end #####"

.PHONY: build
build: precondition ## Builds all the dockerfiles in the repository.
	@echo "##### build all image step start #####"
	@$(CURDIR)/build-all.sh
	@echo "##### build all image step end #####"


check_defined = $(strip $(foreach 1,$1, \
				$(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = $(if $(value $1),, \
				  $(error Undefined $1$(if $2, ($2))$(if $(value @), \
				  required by target '$@')))

.PHONY: run
run: precondition ## Run a Dockerfile from the command at the top of the file (ex. DIR=curl).
	@echo "##### run a container step start #####"
	@:$(call check_defined, DIR, directory of the Dockefile)
	@$(CURDIR)/run.sh $(DIR)
	@echo "##### run a container step end #####"

REGISTRY := docker.io/yakirinp
VERSION := latest
.PHONY: image
image: precondition ## Build a Dockerfile (ex. DIR=telnet).
	@echo "##### build a image step start #####"
	@:$(call check_defined, DIR, directory of the Dockefile)
	$(CONTAINER_BUILD) $(REGISTRY)/$(subst /,:,$(patsubst %/,%,$(DIR))):$(VERSION) ./$(DIR)
	@echo "##### build a image end #####"

.PHONY: clean
clean:
	@echo "##### clean step start #####"
	@echo "clean image etc.."
	@echo "##### clean step end #####"

.PHONY: test
test: ## Run the tests
	@$(CURDIR)/test.sh

.PHONY: all
all: precondition test clean ## Build all and push

.PHONY: help
help:
	@grep -E "^[a-zA-Z_-]+:.*?## .*$$" $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS=":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
