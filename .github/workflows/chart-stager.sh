#!/bin/sh
#
# Copies public and private Helm charts to the private demo registry.
# spell-checker: disable

error()
{
    echo "$0: $*" >&2
    exit 1
}

[ -n "${OCI_REGISTRY}" ] || error "OCI_REGISTRY environment variable is required to be set"

command -v helm >/dev/null 2>/dev/null || error "$0: helm is required on path"

awk '!/^($|#)/ {print}' <<EOF |
https://helm.nginx.com/stable/nim 2.1.0
oci://ghcr.io/nginx/charts/nginx-gateway-fabric 2.4.2
oci://harbor.calypsoai.app/calypsoai/cai-moderator 1.4.13
oci://harbor.calypsoai.app/calypsoai/cai-scanner 2.4.0
oci://harbor.calypsoai.app/calypsoai/cai-redteam 1.14.6
oci://registry.k8s.io/gateway-api-inference-extension/charts/inferencepool v1.0.1
EOF

while read -r src ver; do
    tmp="$(mktemp -d)"
    scheme="${src%%://*}"
    dest="${src##*://}"
    dest="${dest%/*}"
    case "${scheme}" in
        oci)
            helm pull --destination "${tmp}" "${src}" --version "${ver}" || error "Failed to pull chart ${src}"
            ;;
        https)
            helm pull --destination "${tmp}" --repo "${src%/*}" "${src##*/}" --version "${ver}" || error Failed to pull chart "${src}"
            ;;
        *)
            error "Unrecoginised chart repo scheme ${scheme}"
            ;;
    esac
    # shellcheck disable=SC2086 # deliberately globbing here to catch naming variations in tarballs, e.g. nim is named nms
    helm push ${tmp}/*tgz "oci://${OCI_REGISTRY}/${dest}" || \
        error "Failed to push to oci://${OCI_REGISTRY}/${dest}"
    [ -z "${KEEP_PULLED_FILES}" ] && rm -rf "${tmp}"
done
