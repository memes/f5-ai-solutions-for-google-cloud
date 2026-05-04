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
postgres:17.9-alpine
redis:7.2-alpine

# NGINX Instance Manager
private-registry.nginx.com/nms/apigw:2.21.0
private-registry.nginx.com/nms/core:2.21.0
private-registry.nginx.com/nms/dpm:2.21.0
private-registry.nginx.com/nms/ingestion:2.21.0
private-registry.nginx.com/nms/integrations:2.21.0
private-registry.nginx.com/nms/secmon:2.21.0

# CalypsoAI and supporting
harbor.calypsoai.app/calypsoai/f5-ai-security-operator:v0.8.1
harbor.calypsoai.app/calypsoai/cai_moderator:v10.13.2.1

# vLLM and GKE Inference Gateway
vllm/vllm-openai:v0.19.0
registry.k8s.io/gateway-api-inference-extension/lora-syncer:v1.2.1
registry.k8s.io/gateway-api-inference-extension/epp:v1.4.0
registry.k8s.io/gateway-api-inference-extension/bbr:v1.4.0

# Arcadia Crypto
sorinboiaf5/arcadia-frontend:v1
sorinboiaf5/arcadia-login:v1
sorinboiaf5/arcadia-stock_transaction:v1
sorinboiaf5/arcadia-stocks:v1
sorinboiaf5/arcadia-users:v1
sorinboiaf5/arcadia-ai:v1
sorinboiaf5/arcadia-ai-rag:v1
EOF

while read -r src; do
    gcrane cp "${src}" "${OCI_REGISTRY}/${src##*://}"
done
