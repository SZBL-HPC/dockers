#!/usr/bin/env bash

set -euo pipefail

# Package data: URL|expected SHA-1. Update these entries when packages change.
packages=(
    "https://github.com/Nesvilab/FragPipe/releases/download/24.0/FragPipe-24.0-linux.zip|535477cb0e0890c37f0571f05d150eafb2c902b4"
    "https://github.com/SZBL-HPC/dockers/releases/download/zip/diatracer-2.2.1.zip|334dc77b5ab2acf9d46dc97c39be653b7088b8ee"
    "https://github.com/SZBL-HPC/dockers/releases/download/zip/IonQuant-1.11.20.zip|fc78b5be42dc0ee192f0949c0eabf590b05c9241"
    "https://github.com/SZBL-HPC/dockers/releases/download/zip/MSFragger-4.4.1.zip|d69c12476faeb26607f832179bbce307b687b53e"
)

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
tmp_file=""

# Keep the checksums here so downloading does not depend on pkg.sha1 at runtime.
sha1sum_command=()
if command -v sha1sum >/dev/null 2>&1; then
    sha1sum_command=(sha1sum)
elif command -v shasum >/dev/null 2>&1; then
    sha1sum_command=(shasum -a 1)
else
    printf 'error: sha1sum or shasum is required\n' >&2
    exit 1
fi

if command -v curl >/dev/null 2>&1; then
    download_command=(curl -fL --retry 3 --retry-delay 2 --connect-timeout 30)
elif command -v wget >/dev/null 2>&1; then
    download_command=(wget --tries=3 --timeout=30)
else
    printf 'error: curl or wget is required\n' >&2
    exit 1
fi

cleanup() {
    if [[ -n "${tmp_file}" ]]; then
        rm -f -- "${tmp_file}"
    fi
}
trap cleanup EXIT

sha1_matches() {
    local expected="$1"
    local file="$2"
    local result

    result="$("${sha1sum_command[@]}" -- "${file}")"
    [[ "${result%% *}" == "${expected}" ]]
}

download_file() {
    local url="$1"
    local file_name="$2"
    local expected="$3"
    local destination="${script_dir}/${file_name}"

    if [[ -f "${destination}" ]] && sha1_matches "${expected}" "${destination}"; then
        printf 'skip: %s (SHA-1 matches)\n' "${file_name}"
        return
    fi

    if [[ -e "${destination}" ]]; then
        printf 'checksum mismatch, redownloading: %s\n' "${file_name}"
    else
        printf 'downloading: %s\n' "${file_name}"
    fi

    tmp_file="$(mktemp "${destination}.tmp.XXXXXX")"
    if [[ "${download_command[0]}" == "curl" ]]; then
        "${download_command[@]}" -o "${tmp_file}" -- "${url}"
    else
        "${download_command[@]}" -O "${tmp_file}" -- "${url}"
    fi

    if ! sha1_matches "${expected}" "${tmp_file}"; then
        printf 'error: SHA-1 mismatch for %s\n' "${file_name}" >&2
        return 1
    fi

    mv -f -- "${tmp_file}" "${destination}"
    tmp_file=""
    printf 'saved: %s\n' "${file_name}"
}

for package in "${packages[@]}"; do
    IFS='|' read -r url expected_sha1 <<< "${package}"
    file_name="${url##*/}"
    file_name="${file_name%%\?*}"
    download_file "${url}" "${file_name}" "${expected_sha1}"
done
