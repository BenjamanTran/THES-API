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
   - **If `_DEPLOY=true` (SSH to GCE):** the identity running the build needs **`roles/compute.instanceAdmin.v1`** (or at least `compute.instances.setMetadata` + `compute.instances.get`) and **`roles/iap.tunnelResourceAccessor`** on the project (or equivalent on the VM). Terraform staging applies this for the **default** Cloud Build SA (`PROJECT_NUMBER@cloudbuild.gserviceaccount.com`); if the trigger uses a **custom** service account, grant the same roles to that account.
   - For GCE auto-deploy: VM service account needs `roles/artifactregistry.reader` to `docker pull`.

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
     --substitutions=_REGION=asia-southeast1,_AR_REPOSITORY=the-s-api-staging,_DEPLOY=false,_GCE_INSTANCE=,_GCE_ZONE=asia-southeast1-a,_GCS_MEDIA_BUCKET=the-s-staging-media88,_GCS_PROJECT_ID=YOUR_PROJECT_ID,_API_PUBLIC_URL=https://api.example.com,_FE_ORIGIN=https://fe.example.com
   ```

   **Avatar / GCS substitutions (API trigger):**

   | Substitution | Example | Notes |
   |--------------|---------|--------|
   | `_GCS_MEDIA_BUCKET` | `the-s-staging-media88` | Private bucket; API proxies `/avatars/...` |
   | `_GCS_PROJECT_ID` | `test-496207` | GCP project id |
   | `_API_PUBLIC_URL` | `https://api.example.com` | Public API base (avatar URLs) |
   | `_FE_ORIGIN` | `https://app.example.com` | CORS |

   Do **not** set `_GOOGLE_APPLICATION_CREDENTIALS` in Cloud Build — org policy blocks SA keys. On **GKE**, use Workload Identity (`roles/storage.objectAdmin` on bucket). On **GCE**, use the VM / runtime service account.

   **GKE:** put the same keys in Terraform `k8s_configmap_data` (not only trigger substitutions). Re-`terraform apply` after changing ConfigMap.

5. **Deploy on GCE:** Cloud Build’s **`deploy-gce`** step runs the deploy commands over IAP SSH (no `/opt/the_s/*.sh` required). For **manual** deploys from your laptop, you can still copy `script/gcp_staging_deploy_on_vm.sh` to the VM (e.g. `/opt/the_s/`), `chmod +x`, and run it with the same four arguments. Configure **`/etc/the_s/api-staging.env`** on the VM for Rails/DB (see script comments). Set trigger substitutions `_DEPLOY=true`, `_GCE_INSTANCE`, `_GCE_ZONE` when ready.

Pipeline: **docker build** (repo-root `Dockerfile`) → **push** `api:$SHORT_SHA` and `api:staging-latest` → optional **IAP SSH** + script on the VM.

**Note:** The Cloud Build pipeline does not run the full test suite yet (MySQL/Redis in CI can be added later).

**Docker / Linux AMD64:** Cloud Build uses `x86_64-linux`. If you lock gems on Apple Silicon only, run `bundle lock --add-platform x86_64-linux` (Ruby 3.4 + Bundler 2.6) and commit `Gemfile.lock` so production Docker builds succeed.
