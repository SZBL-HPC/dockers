PODMAN ?= podman
IMAGE ?= fragpipe:24.0-szbl
APPTAINER_IMAGE ?= apptainer-in-docker:package
IMAGE_MAX_AGE_DAYS ?= 7
FORCE_TAG ?= $(shell date -u +%Y%m%d%H%M%S)
TAR ?= fragpipe-24.0-szbl.tar
SIF ?= fragpipe-24.0-szbl.sif

.PHONY: all build download tar sif force-build

all: sif

build: download
	@created="$$( $(PODMAN) image inspect --format '{{.Created}}' "$(IMAGE)" 2>/dev/null || true )"; \
	if [ -n "$$created" ]; then \
		created_epoch="$$(date -d "$$created" +%s 2>/dev/null || true)"; \
		if [ -z "$$created_epoch" ]; then \
			created_epoch="$$(date -j -u -f '%Y-%m-%d %H:%M:%S' "$${created%%.*}" +%s 2>/dev/null || true)"; \
		fi; \
		now_epoch="$$(date +%s)"; \
		if [ -n "$$created_epoch" ] && [ "$$created_epoch" -ge "$$((now_epoch - $(IMAGE_MAX_AGE_DAYS) * 24 * 60 * 60))" ]; then \
			printf 'skip: %s (created within %s days)\n' "$(IMAGE)" "$(IMAGE_MAX_AGE_DAYS)"; \
			exit 0; \
		fi; \
	fi; \
	$(PODMAN) build --format docker --tag "$(IMAGE)" .

download:
	./pkg/download.sh

tar: build
	$(PODMAN) save --format docker-archive --output "$(TAR)" "$(IMAGE)"

sif: tar
	$(PODMAN) run --rm \
		-v "$(CURDIR):/work" \
		$(APPTAINER_IMAGE) \
		build "$(SIF)" "docker-archive://$(TAR)"

# Append a second-resolution UTC timestamp to the image tag.
force-build:
	$(MAKE) build IMAGE="$(IMAGE)-$(FORCE_TAG)"
