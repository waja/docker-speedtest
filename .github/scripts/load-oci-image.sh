#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
	echo "Usage: $0 IMAGE_NAME OCI_ARCHIVE" >&2
	exit 2
fi

image_name="$1"
oci_archive="$2"
local_image="localhost:5000/foobar/${image_name}:latest"

if [[ ! -s "$oci_archive" ]]; then
	echo "::error::OCI archive is missing or empty: $oci_archive"
	exit 1
fi

skopeo copy --all --dest-tls-verify=false \
	"oci-archive:${oci_archive}:latest" \
	"docker://${local_image}"

docker pull "$local_image"
