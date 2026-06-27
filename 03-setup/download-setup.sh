#!/usr/bin/env bash
# download-setup.sh
# Script to download Ornith-1.0-35B Q3_K_M model and verify integrity.
# Uses environment variables for configurability (see .env.example).

set -euo pipefail

# Default values (can be overridden by environment)
: "${MODEL_REPO:=deepreinforce-ai/Ornith-1.0}"
: "${MODEL_FILENAME:=ornith-1.0-35b-q3_k_m.gguf}"
: "${MODEL_DIR:=$(pwd)/models}"
: "${HF_DOWNLOAD_URL:=https://huggingface.co/${MODEL_REPO}/resolve/main/${MODEL_FILENAME}}"
: "${MODEL_SHA256:=""}"  # If set, verify after download

# Create model directory
mkdir -p "${MODEL_DIR}"

MODEL_PATH="${MODEL_DIR}/${MODEL_FILENAME}"

echo "Checking for existing model at ${MODEL_PATH}..."
if [[ -f "${MODEL_PATH}" ]]; then
    echo "Model file already exists."
    if [[ -n "${MODEL_SHA256}" ]]; then
        echo "Verifying checksum..."
        if sha256sum --status <<<"${MODEL_SHA256}  ${MODEL_PATH}"; then
            echo "Checksum OK."
        else
            echo "Checksum mismatch! Redownloading..."
            rm "${MODEL_PATH}"
        fi
    else
        echo "No checksum configured; skipping verification."
    fi
else
    echo "Model not found. Downloading from ${HF_DOWNLOAD_URL}..."
    # Use wget or curl; prefer wget if available
    if command -v wget >/dev/null 2>&1; then
        wget -O "${MODEL_PATH}" "${HF_DOWNLOAD_URL}"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o "${MODEL_PATH}" "${HF_DOWNLOAD_URL}"
    else
        echo "Error: neither wget nor curl is installed." >&2
        exit 1
    fi
    echo "Download complete."

    if [[ -n "${MODEL_SHA256}" ]]; then
        echo "Verifying checksum..."
        if sha256sum --status <<<"${MODEL_SHA256}  ${MODEL_PATH}"; then
            echo "Checksum OK."
        else
            echo "Checksum mismatch! Removing corrupted file." >&2
            rm "${MODEL_PATH}"
            exit 1
        fi
    fi
fi

echo "Model ready at ${MODEL_PATH}"
echo "You can now run llama-server with split configuration."
echo "Example usage:"
echo "  export LLAMA_SPLIT_MODE=1"
echo "  export LLAMA_SPLIT_0=28   # P40 layers"
echo "  export LLAMA_SPLIT_1=20   # 3050 layers"
echo "  ./llama-server -m ${MODEL_PATH} --host 0.0.0.0 --port 8080"