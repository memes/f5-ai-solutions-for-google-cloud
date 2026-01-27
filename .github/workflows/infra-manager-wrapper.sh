#!/bin/sh
#
# Script to invoke Infrastructure Manager via gcloud CLI

set -e

# Build arguments common to plan and apply functions. Will report an error if required environment variables are not
# provided.
build_args()
{
    args="$1"
    # Verify the required arguments first to fail early
    [ -z "${DEPLOYMENT_SERVICE_ACCOUNT_NAME}" ] && \
        echo "ERROR: DEPLOYMENT_SERVICE_ACCOUNT_NAME environment variable must be set" && \
        exit 1
    args="${args:+"${args} "}--service-account='${DEPLOYMENT_SERVICE_ACCOUNT_NAME}'"
    [ -z "${DEPLOYMENT_GIT_URL}" ] && \
        echo "ERROR: DEPLOYMENT_GIT_URL environment variable must be set" && \
        exit 1
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
    [ -z "${DEPLOYMENT_PROJECT_ID}" ] && \
        echo "ERROR: DEPLOYMENT_PROJECT_ID environment variable must be set" && \
        exit 1
    [ -z "${DEPLOYMENT_REGION}" ] && \
        echo "ERROR: DEPLOYMENT_REGION environment variable must be set" && \
        exit 1
    [ -z "${DEPLOYMENT_GIT_SHA}" ] && \
        echo "ERROR: DEPLOYMENT_GIT_SHA environment variable must be set" && \
        exit 1
    echo "projects/${DEPLOYMENT_PROJECT_ID}/locations/${DEPLOYMENT_REGION}/previews/${DEPLOYMENT_GIT_SHA}"
}

# Generates the fully-qualified Infrastructure Manager name for this deployment
deployment_name()
{
    [ -z "${DEPLOYMENT_PROJECT_ID}" ] && \
        echo "ERROR: DEPLOYMENT_PROJECT_ID environment variable must be set" && \
        exit 1
    [ -z "${DEPLOYMENT_REGION}" ] && \
        echo "ERROR: DEPLOYMENT_REGION environment variable must be set" && \
        exit 1
    [ -z "${DEPLOYMENT_ID}" ] && \
        echo "ERROR: DEPLOYMENT_ID environment variable must be set" && \
        exit 1
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
    [ -z "${DEPLOYMENT_GIT_SHA}" ] && \
        echo "ERROR: DEPLOYMENT_GIT_SHA environment variable must be set" && \
        exit 1
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
    gcloud infra-manager deployments delete "$(deployment_name)"
}

case "$1" in
    apply)
        apply
        ;;
    delete)
        delete
        ;;
    *)
        plan
        ;;
esac
