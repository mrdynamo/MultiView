#!/usr/bin/env zsh
set -euo pipefail

# build-push.sh
# Build the backend (root) and frontend (./frontend) Docker images,
# tag them as mrdynamo/multiview:backend and mrdynamo/multiview:frontend,
# and push to Docker Hub.
#
# Usage:
#  - Interactive login: run `docker login` beforehand, then ./build-push.sh
#  - Non-interactive login: set DOCKERHUB_USER and DOCKERHUB_PASS and run the script
#
# Note: make executable with `chmod +x build-push.sh` before running.

REPO="mrdynamo/multiview"
IMAGE_TAG="latest"

LOCAL_IMAGE="multiview:latest"
BUILD_DIR="."

info(){ echo "[INFO] $*" }
err(){ echo "[ERROR] $*" >&2 }

if ! command -v docker >/dev/null 2>&1; then
  err "docker is not installed or not in PATH"
  exit 1
fi

info "Starting build/push for ${REPO}:${IMAGE_TAG} (combined image)"

# Optional non-interactive login
if [[ -n "${DOCKERHUB_USER:-}" && -n "${DOCKERHUB_PASS:-}" ]]; then
  info "Logging in to Docker Hub as ${DOCKERHUB_USER} (from env)"
  echo "${DOCKERHUB_PASS}" | docker login --username "${DOCKERHUB_USER}" --password-stdin
else
  info "No DOCKERHUB_USER/DOCKERHUB_PASS provided. Ensure you're logged in with 'docker login' before pushing."
fi

info "Building combined image (tag: ${LOCAL_IMAGE}) from ${BUILD_DIR} with no cache"
docker build --no-cache --pull -t "${LOCAL_IMAGE}" "${BUILD_DIR}"

info "Tagging image for Docker Hub repository ${REPO}:${IMAGE_TAG}"
docker tag "${LOCAL_IMAGE}" "${REPO}:${IMAGE_TAG}"

info "Pushing ${REPO}:${IMAGE_TAG}"
docker push "${REPO}:${IMAGE_TAG}"

info "Push complete. Local and remote tags for ${REPO}:"
docker images "${REPO}" --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" || true

info "Done. If you need this script to be executable, run: chmod +x build-push.sh"
