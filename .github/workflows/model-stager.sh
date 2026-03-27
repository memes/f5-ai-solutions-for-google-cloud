#!/bin/sh
#
# Copies Hugging Face models to a GCS bucket.
# spell-checker: disable

error()
{
    echo "$0: $*" >&2
    exit 1
}

# cleanup() {
#     hf auth logout
# }

[ -n "${HF_TOKEN}" ] || error "HF_TOKEN environment variable is required to be set"
[ -n "${MODEL_BUCKETS}" ] || error "MODEL_BUCKETS environment variable is required to be set"

command -v hf >/dev/null 2>/dev/null || error "$0: hf is required on path"
command -v gcloud >/dev/null 2>/dev/null || error "$0: gcloud is required on path"

# trap cleanup 0 1 2 3 6 15
# hf auth login --token "${HF_TOKEN}" --no-add-to-git-credential

awk '!/^($|#)/ {print}' <<EOF |
meta-llama/Llama-3.1-8B
google/gemma-3-1b-it
EOF

while read -r model; do
    hf download --token "${HF_TOKEN}" --type model "${model}" || \
        error "Failed to download hugging face model ${model}"
done
for bucket in ${MODEL_BUCKETS}; do
    gcloud storage rsync --recursive --preserve-posix --no-ignore-symlinks --checksums-only \
        "${HOME}/.cache/huggingface/hub/" "gs://${bucket}/" || \
            error "Failed to sync contents of ${HOME}/.cache/huggingface/hub/ to gs://${bucket}/"
done
