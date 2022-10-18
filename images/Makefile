IMAGE?="."
export DOCKER_ORG?=pkgr
export PKGR_VERSION?=$(shell git rev-parse --verify HEAD)

.PHONY: build push

build:
	@echo PKGR_VERSION=$(PKGR_VERSION)
	find $(IMAGE) -name Dockerfile -print0 | xargs -0 -n1 --max-procs=$(shell nproc) $(shell pwd)/dockerize

push:
	@echo PKGR_VERSION=$(PKGR_VERSION)
	find $(IMAGE) -name Dockerfile -print0 | xargs -0 -n1 --max-procs=$(shell nproc) $(shell pwd)/push

release: build push
