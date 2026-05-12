# API (Rails)

Ruby version: see `.ruby-version` (currently 3.4.2). Local development: parent repo `docker-compose.yml` (service `api`).

## Staging: Cloud Build (push `staging`, chỉ thư mục `api/`)

1. **Bật API & kết nối GitHub** (Console): Cloud Build → Connect repository (GitHub App) → chọn repo chứa cả monorepo (ví dụ `THE_S`).

2. **Tạo Artifact Registry** (một lần):

   ```bash
   gcloud artifacts repositories create the-s-api-staging \
     --repository-format=docker \
     --location=asia-southeast1 \
     --project=YOUR_PROJECT_ID
   ```

3. **Gán quyền** cho Cloud Build service account (thay `PROJECT_NUMBER`):

   - `roles/artifactregistry.writer`
   - Nếu deploy GCE: `roles/compute.instanceAdmin.v1` (hoặc tối thiểu SSH/IAP), `roles/iap.tunnelResourceAccessor` trên VM; VM dùng SA có `roles/artifactregistry.reader` để `docker pull`.

4. **Tạo trigger** (Console *hoặc* CLI):

   - **Branch:** `^staging$`
   - **Included files:** `api/**` (chỉ chạy khi commit đụng `api/`)
   - **Config:** Cloud Build configuration file → `api/cloudbuild.staging.yaml`
   - **Substitutions (tùy chọn):** `_REGION`, `_AR_REPOSITORY`, `_DEPLOY=true`, `_GCE_INSTANCE`, `_GCE_ZONE`

   ```bash
   gcloud builds triggers create github \
     --project=YOUR_PROJECT_ID \
     --name=api-staging-on-api-push \
     --region=global \
     --repo-name=YOUR_GITHUB_REPO \
     --repo-owner=YOUR_ORG_OR_USER \
     --branch-pattern="^staging$" \
     --build-config=api/cloudbuild.staging.yaml \
     --included-files="api/**" \
     --substitutions=_REGION=asia-southeast1,_AR_REPOSITORY=the-s-api-staging,_DEPLOY=false,_GCE_INSTANCE=,_GCE_ZONE=asia-southeast1-a
   ```

   Đổi `--repo-owner` / `--repo-name` theo Cloud Build Repositories (sau khi connect). Nếu CLI báo deprecated, dùng form **Trigger v2** trong Console hoặc `gcloud builds triggers create manual` với spec YAML — tham khảo [Cloud Build triggers](https://cloud.google.com/build/docs/automating-builds/create/github-triggers).

5. **Deploy lên GCE:** copy `script/gcp_staging_deploy_on_vm.sh` lên VM (ví dụ `/opt/the_s/`), `chmod +x`, cấu hình biến môi trường Rails/DB (hoặc sửa script cho `docker compose`). Đặt trigger `_DEPLOY=true` và `_GCE_INSTANCE=tên-vm`.

Pipeline: **docker build** (`Dockerfile`) → **push** `api:$SHORT_SHA` và `api:staging-latest` → (optional) **IAP SSH** + script trên VM.

**Lưu ý:** Chưa chạy test suite trong Cloud Build (cần MySQL/Redis/ES trong CI). Có thể bổ sung sau (Compose CI hoặc dịch vụ test riêng).
