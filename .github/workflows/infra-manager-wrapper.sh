#!/bin/sh
#
# Script to invoke Infrastructure Manager via gcloud CLI

set -e

# Echo message to stdout for capture by GitHub runner and terminate
error()
{
    echo "$0: ERROR: $*"
    exit 1
}

# Build arguments common to plan and apply functions. Will report an error if required environment variables are not
# provided.
build_args()
{
    args="$1"
    # Verify the required arguments first to fail early
    [ -z "${DEPLOYMENT_SERVICE_ACCOUNT_NAME}" ] && error "DEPLOYMENT_SERVICE_ACCOUNT_NAME environment variable must be set"
    args="${args:+"${args} "}--service-account='${DEPLOYMENT_SERVICE_ACCOUNT_NAME}'"
    [ -z "${DEPLOYMENT_GIT_URL}" ] && error "DEPLOYMENT_GIT_URL environment variable must be set"
    args="${args:+"${args} "}--git-source-repo='${DEPLOYMENT_GIT_URL}'"

    # Optional arguments
    [ -n "${DEPLOYMENT_GIT_REF}" ] && \
        args="${args:+"${args} "}--git-source-ref='$(python3 -c "import urllib.parse; print(urllib.parse.quote_plus('${DEPLOYMENT_GIT_REF}'))")'"
    [ -n "${DEPLOYMENT_GIT_SOURCE_DIRECTORY}" ] && \
        args="${args:+"${args} "}--git-source-directory='${DEPLOYMENT_GIT_SOURCE_DIRECTORY}'"
    [ -n "${DEPLOYMENT_LABELS}" ] && \
        args="${args:+"${args} "}--labels='${DEPLOYMENT_LABELS}'"
    [ -n "${DEPLOYMENT_ANNOTATIONS}" ] && \
        args="${args:+"${args} "}--annotations='${DEPLOYMENT_ANNOTATIONS}'"
    [ -n "${DEPLOYMENT_INPUTS_FILE}" ] && [ -r "${DEPLOYMENT_INPUTS_FILE}" ] && \
        args="${args:+"${args} "}--inputs-file='${DEPLOYMENT_INPUTS_FILE}'"
    echo "${args}"
}

# Generates the fully-qualified Infrastructure Manager name for this preview
preview_name()
{
    [ -z "${DEPLOYMENT_PROJECT_ID}" ] && error "DEPLOYMENT_PROJECT_ID environment variable must be set"
    [ -z "${DEPLOYMENT_REGION}" ] && error "DEPLOYMENT_REGION environment variable must be set"
    [ -z "${DEPLOYMENT_GIT_SHA}" ] && error "DEPLOYMENT_GIT_SHA environment variable must be set"
    echo "projects/${DEPLOYMENT_PROJECT_ID}/locations/${DEPLOYMENT_REGION}/previews/${DEPLOYMENT_GIT_SHA}"
}

# Generates the fully-qualified Infrastructure Manager name for this deployment
deployment_name()
{
    [ -z "${DEPLOYMENT_PROJECT_ID}" ] && error "DEPLOYMENT_PROJECT_ID environment variable must be set"
    [ -z "${DEPLOYMENT_REGION}" ] && error "DEPLOYMENT_REGION environment variable must be set"
    [ -z "${DEPLOYMENT_ID}" ] && error "DEPLOYMENT_ID environment variable must be set"
    echo "projects/${DEPLOYMENT_PROJECT_ID}/locations/${DEPLOYMENT_REGION}/deployments/${DEPLOYMENT_ID}"
}

plan()
{
    # Delete existing preview for this commit, if it exists
    preview_name="$(preview_name)"
    gcloud infra-manager previews delete --quiet "${preview_name}" 2>/dev/null || true

    args="$(build_args "previews create '${preview_name}'")"

    # See if there is an existing deployment to attach to the preview arguments
    deployment_name="$(deployment_name)"
    [ -n "$(gcloud infra-manager deployments describe "${deployment_name}" --format "value(name)" 2>/dev/null || true)" ] && \
        args="${args:+"${args} "}--deployment='${deployment_name}'"

    eval "gcloud infra-manager ${args}"

    # Export the tfplan from preview
    [ -z "${DEPLOYMENT_GIT_SHA}" ] && error "DEPLOYMENT_GIT_SHA environment variable must be set"
    gcloud infra-manager previews export "${preview_name}" --file="${DEPLOYMENT_GIT_SHA}"
}

apply()
{
    args="$(build_args "deployments apply '$(deployment_name)'")"
    [ -n "${DEPLOYMENT_TF_VERSION}" ] && \
        args="${args:+"${args} "}--tf-version-constraint='${DEPLOYMENT_TF_VERSION}'"
    eval "gcloud infra-manager ${args}"
}

delete()
{
    gcloud infra-manager deployments delete --quiet "$(deployment_name)"
}

cleanup()
{
    if [ -n "${lock_id}" ]; then
        deployment_name="$(deployment_name)"
        gcloud infra-manager deployments unlock --quiet "${deployment_name}" --lock-id "${lock_id}" >/dev/null || \
            echo "$0: ERROR: Failed to unlock ${deployment_name}"
    fi
    [ -f "${DEPLOYMENT_GIT_SHA}.tfstate" ] && rm "${DEPLOYMENT_GIT_SHA}.tfstate"
    return 0
}

output()
{
    [ -z "${DEPLOYMENT_GIT_SHA}" ] && error "DEPLOYMENT_GIT_SHA environment variable must be set"
    # Only generate an output if there is a deployment that can be sourced for Terraform state
    deployment_name="$(deployment_name)"
    if [ -n "$(gcloud infra-manager deployments describe "${deployment_name}" --format "value(name)" 2>/dev/null || true)" ]; then
        lock_id="$(gcloud infra-manager deployments lock "${deployment_name}" --format "value(lockId)" || true)"
        [ -z "${lock_id}" ] && error "Failed to get lock on ${deployment_name}"
        state_url="$(gcloud infra-manager deployments export-statefile "${deployment_name}" --format "get(signedUri)" || true)"
        [ -z "${state_url}" ] && error "Failed to get storage URL for statefile"
        curl -fsSL --output "${DEPLOYMENT_GIT_SHA}.tfstate" "${state_url}" || \
            error "Failed to retrieve state file from storage"
        [ -s "${DEPLOYMENT_GIT_SHA}.tfstate" ] || error "State file appears to be missing or empty"
        terraform output -no-color -state="${DEPLOYMENT_GIT_SHA}.tfstate" > "${DEPLOYMENT_GIT_SHA}.output.hcl" || \
            error "Failed to generate output from ${DEPLOYMENT_GIT_SHA}.tfstate"
    fi
}

trap cleanup 0 1 2 3 6 15

case "$1" in
    apply)
        apply
        ;;
    delete)
        delete
        ;;
    output)
        output
        ;;
    *)
        plan
        ;;
esac
