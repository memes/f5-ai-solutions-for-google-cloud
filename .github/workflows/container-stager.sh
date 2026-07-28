#!/bin/sh
#
# Copies containers from public and private registries to the private demo registry.
# spell-checker: disable

if [ -z "${OCI_REGISTRY}" ]; then
    echo "$0: OCI_REGISTRY environment variable is required to be set" >&2
    exit 1
fi

if ! command -v gcrane >/dev/null 2>/dev/null; then
    echo "$0: gcrane is required on path" >&2
    exit 1
fi

awk '!/^($|#)/ {print}' <<EOF |
# Debugging/utility containers
busybox:1.38.0@sha256:fd8d9aa63ba2f0982b5304e1ee8d3b90a210bc1ffb5314d980eb6962f1a9715d
curlimages/curl:8.21.0@sha256:7c12af72ceb38b7432ab85e1a265cff6ae58e06f95539d539b654f2cfa64bb13
ghcr.io/memes/terraform-google-private-bastion/forward-proxy:4.0.2@sha256:9fa3fa77c867614976366c1edfd4a5f0e411f47e3c914c14e69bf45bedd9ed25
postgres:17.10-alpine@sha256:742f40ea20b9ff2ff31db5458d127452988a2164df9e17441e191f3b72252193
redis:7.4.10-alpine@sha256:e7723ff73d963f5cc6d9c4643ea3d989527a402a319239054e9472a7fb9219a2

EOF

while read -r src; do
    gcrane cp "${src}" "${OCI_REGISTRY}/${src##*://}"
done
