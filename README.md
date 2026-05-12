# API (Rails)

Ruby version: see `.ruby-version` in the **API repository** (e.g. 3.4.2). Local development: clone **THE_S** for `docker-compose.yml` and run the `api` service against this codebase.

## Repositories

| Repo | Contents |
|------|----------|
| **THE_S** | Terraform, Docker Compose (local/dev infra) |
| **API** | Rails app, `Dockerfile`, tests |
| **FE** | Next.js app, its own `Dockerfile` and Cloud Build config |

CI templates for GCP live under `api/` in THE_S for convenience: **copy** `cloudbuild.staging.yaml` (and `script/gcp_staging_deploy_on_vm.sh` for VM deploy) into your **API** repo, usually as `cloudbuild.staging.yaml` at the **repository root**, then point the Cloud Build trigger at that path.

## Staging: Cloud Build (API repo)

1. **Connect the API repository** in Cloud Build (GitHub App): Cloud Build → Repositories → Connect repository → select your **API** repo (not THE_S).

2. **Create Artifact Registry** (once per project):

   ```bash
   gcloud artifacts repositories create the-s-api-staging \
     --repository-format=docker \
     --location=asia-southeast1 \
     --project=YOUR_PROJECT_ID
   ```

3. **IAM** for the Cloud Build service account (replace `PROJECT_NUMBER`):

   - `roles/artifactregistry.writer`
   - For GCE auto-deploy: SSH via IAP — e.g. `roles/compute.instanceAdmin.v1` (or narrower), `roles/iap.tunnelResourceAccessor` on the VM; the VM’s service account needs `roles/artifactregistry.reader` to `docker pull`.

4. **Trigger** (Console or CLI):

   - **Branch:** e.g. `^staging$`
   - **Included files:** leave empty or use `**` (entire API repo is the source).
   - **Config file:** `cloudbuild.staging.yaml` at repo root (after you copy the template from THE_S).

   Example CLI (adjust repo owner/name and trigger v2 if your `gcloud` version differs):

   ```bash
   gcloud builds triggers create github \
     --project=YOUR_PROJECT_ID \
     --name=api-staging \
     --region=global \
     --repo-name=YOUR_API_REPO \
     --repo-owner=YOUR_ORG_OR_USER \
     --branch-pattern="^staging$" \
     --build-config=cloudbuild.staging.yaml \
     --substitutions=_REGION=asia-southeast1,_AR_REPOSITORY=the-s-api-staging,_DEPLOY=false,_GCE_INSTANCE=,_GCE_ZONE=asia-southeast1-a
   ```

5. **Deploy on GCE:** on the VM, place `gcp_staging_deploy_on_vm.sh` under e.g. `/opt/the_s/`, `chmod +x`, configure Rails/DB env (see script comments). Set trigger substitutions `_DEPLOY=true`, `_GCE_INSTANCE`, `_GCE_ZONE` when ready.

Pipeline: **docker build** (repo-root `Dockerfile`) → **push** `api:$SHORT_SHA` and `api:staging-latest` → optional **IAP SSH** + script on the VM.

**Note:** The Cloud Build pipeline does not run the full test suite yet (MySQL/Redis in CI can be added later).

**Docker / Linux AMD64:** Cloud Build uses `x86_64-linux`. If you lock gems on Apple Silicon only, run `bundle lock --add-platform x86_64-linux` (Ruby 3.4 + Bundler 2.6) and commit `Gemfile.lock` so production Docker builds succeed.
