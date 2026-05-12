#!/usr/bin/env bash
# Install on the staging API VM (e.g. /opt/the_s/gcp_staging_deploy_on_vm.sh, mode 755, root-owned).
# Cloud Build calls this via IAP SSH with: REGION PROJECT_ID REPO_ID GIT_SHA
set -euo pipefail

REGION="${1:?}"
PROJECT_ID="${2:?}"
REPO_ID="${3:?}"
TAG="${4:?}"

IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_ID}/api:${TAG}"

# VM service account needs roles/artifactregistry.reader (or equivalent) on this repo.
# Ensure Artifact Registry Docker auth once on the VM, e.g.:
#   sudo apt-get install -y google-cloud-sdk-docker-credential-gcr && \
#   docker-credential-gcr configure-docker --registries="${REGION}-docker.pkg.dev"

docker pull "${IMAGE}"

# Adjust to your runtime: compose file path, container name, or systemd unit.
# Example: single container replace
if docker ps -a --format '{{.Names}}' | grep -qx api-staging; then
  docker stop api-staging || true
  docker rm api-staging || true
fi

docker run -d --name api-staging --restart unless-stopped -p 127.0.0.1:3000:80 \
  -e RAILS_ENV=staging \
  -e RAILS_MASTER_KEY="${RAILS_MASTER_KEY:-}" \
  -e API_DATABASE_PASSWORD="${API_DATABASE_PASSWORD:-}" \
  -e DATABASE_HOST="${DATABASE_HOST:-127.0.0.1}" \
  "${IMAGE}"

echo "Deployed ${IMAGE}"
