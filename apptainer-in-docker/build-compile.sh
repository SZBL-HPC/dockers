#!/usr/bin/env bash
set -euo pipefail

if ! command -v podman >/dev/null 2>&1; then
    printf 'podman is required to build this image\n' >&2
    exit 127
fi

repo_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
commitish="${1:-release-1.5}"
image="${2:-apptainer-in-docker:compile-${commitish//\//-}}"

podman build \
    --pull=always \
    --build-arg "APPTAINER_COMMITISH=$commitish" \
    --tag "$image" \
    --file "$repo_dir/compile/Dockerfile" \
    "$repo_dir"
