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
busybox:1.37.0
curlimages/curl:8.18.0
ghcr.io/memes/terraform-google-private-bastion/forward-proxy:4.0.2
postgres:15.16-alpine

# NGINX Instance Manager
private-registry.nginx.com/nms/apigw:2.21.0
private-registry.nginx.com/nms/core:2.21.0
private-registry.nginx.com/nms/dpm:2.21.0
private-registry.nginx.com/nms/ingestion:2.21.0
private-registry.nginx.com/nms/integrations:2.21.0
private-registry.nginx.com/nms/secmon:2.21.0

# CalypsoAI and supporting
harbor.calypsoai.app/calypsoai/cai_moderator:v9.133.3.6
harbor.calypsoai.app/calypsoai/cai_scanner:v2.4.0
harbor.calypsoai.app/calypsoai/kubeai:v0.22.1
harbor.calypsoai.app/calypsoai/kubeai-model-loader:v0.14.0
harbor.calypsoai.app/calypsoai/cai_workflows:v1.95.3
harbor.calypsoai.app/calypsoai/cai-redteam-worker:v1.0.7
vllm/vllm-openai:v0.10.2
vllm/vllm-tpu:23194d83e8f2a6783b0d8c275f5f8a22faab9aec
prefecthq/prefect:3.1.12-python3.11
prefecthq/prefect:3.1.12-python3.11-kubernetes
prefecthq/prometheus-prefect-exporter:1.6.7
EOF

while read -r src; do
    gcrane cp "${src}" "${OCI_REGISTRY}/${src##*://}"
done
