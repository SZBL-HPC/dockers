PODMAN ?= podman
IMAGE ?= fragpipe:24.0-szbl

.PHONY: build download

build: download
	$(PODMAN) build --format docker --tag $(IMAGE) .

download:
	./pkg/download.sh
