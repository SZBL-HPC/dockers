#!/usr/bin/env bash
set -euo pipefail

if ! command -v podman >/dev/null 2>&1; then
    printf 'podman is required to build this image\n' >&2
    exit 127
fi

repo_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
image="${1:-apptainer-in-docker:package}"

podman build \
    --pull=always \
    --tag "$image" \
    --file "$repo_dir/package/Dockerfile" \
    "$repo_dir"
