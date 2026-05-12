#!/usr/bin/env bash
# Optional: run manually on the VM (e.g. after copying to /opt/the_s/). Cloud Build deploy-gce
# embeds the same logic in api/cloudbuild.staging.yaml (base64 over IAP SSH) — keep these in sync.
# Cloud Build (when using this file directly) calls with: REGION PROJECT_ID REPO_ID GIT_SHA
set -euo pipefail

REGION="${1:?}"
PROJECT_ID="${2:?}"
REPO_ID="${3:?}"
TAG="${4:?}"

IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_ID}/api:${TAG}"

# Rails / DB secrets: create on the VM once (root-only), e.g.:
#   sudo install -d -m 755 /etc/the_s
#   sudo sh -c 'umask 077; cat > /etc/the_s/api-staging.env' <<'EOF'
#   RAILS_MASTER_KEY=...
#   DB_HOST=127.0.0.1
#   DB_USERNAME=root
#   DB_PASSWORD=...
#   (If you add a `staging:` section mirroring production credentials:)
#   API_DATABASE_PASSWORD=...
#   EOF
# One KEY=value per line. Optional: add REDIS_URL, etc., if your app reads them at boot.
ENV_FILE="/etc/the_s/api-staging.env"
DOCKER_ENV_FILE=()
if [[ -f "${ENV_FILE}" ]]; then
  DOCKER_ENV_FILE=(--env-file "${ENV_FILE}")
fi

# Extra -e only when no env file: avoid empty -e overriding values from --env-file.
EXTRA_ENV=()
if [[ ! -f "${ENV_FILE}" ]]; then
  EXTRA_ENV=(
    -e RAILS_MASTER_KEY="${RAILS_MASTER_KEY:-}"
    -e API_DATABASE_PASSWORD="${API_DATABASE_PASSWORD:-}"
    -e DB_HOST="${DB_HOST:-127.0.0.1}"
  )
fi

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
  "${DOCKER_ENV_FILE[@]}" \
  "${EXTRA_ENV[@]}" \
  -e RAILS_ENV=staging \
  "${IMAGE}"

echo "Deployed ${IMAGE}"
