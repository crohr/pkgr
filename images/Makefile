IMAGE?="."
export DOCKER_ORG?=pkgr
export PKGR_VERSION

.PHONY: build push

build:
	find $(IMAGE) -name Dockerfile -print0 | xargs -0 -n1 --max-procs=$(shell nproc) $(shell pwd)/dockerize

push:
	find $(IMAGE) -name Dockerfile -print0 | xargs -0 -n1 --max-procs=$(shell nproc) $(shell pwd)/push

release: build push
