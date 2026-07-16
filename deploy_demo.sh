#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-732190342674}"
REGION="${REGION:-us-central1}"
SERVICE_NAME="${SERVICE_NAME:-dominion-demo}"
AR_REPO="${AR_REPO:-dominion-demo-repo}"
DOCKERFILE="${DOCKERFILE:-Dockerfile.production}"
BUILD_CONTEXT="${BUILD_CONTEXT:-.}"
TAG="${TAG:-latest}"
APP_VERSION="${APP_VERSION:-2026-07-16-claim-control-cutover}"
DEMO_HOST="${DEMO_HOST:-https://www.fractal5solutions.com/demo}"

IMAGE_REF="${REGION}-docker.pkg.dev/${PROJECT_ID}/${AR_REPO}/${SERVICE_NAME}:${TAG}"

printf '%s\n' "== Fractal5 Demo Deploy =="
printf 'Project:  %s\n' "${PROJECT_ID}"
printf 'Region:   %s\n' "${REGION}"
printf 'Service:  %s\n' "${SERVICE_NAME}"
printf 'Image:    %s\n' "${IMAGE_REF}"
printf 'Version:  %s\n' "${APP_VERSION}"

if ! gcloud auth list --filter=status:ACTIVE --format='value(account)' | grep -q '@'; then
  echo "ERROR: no active gcloud identity found. Run: gcloud auth login"
  exit 1
fi

gcloud config set project "${PROJECT_ID}" >/dev/null

PROJECT_NUMBER="$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')"
BUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

for api in run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com compute.googleapis.com dns.googleapis.com iap.googleapis.com; do
  gcloud services enable "${api}" --quiet >/dev/null
done

if ! gcloud artifacts repositories describe "${AR_REPO}" --project="${PROJECT_ID}" --location="${REGION}" >/dev/null 2>&1; then
  gcloud artifacts repositories create "${AR_REPO}" \
    --project="${PROJECT_ID}" \
    --location="${REGION}" \
    --repository-format=docker \
    --description="Docker repo for Fractal5 demo"
fi

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${BUILD_SA}" \
  --role="roles/artifactregistry.writer" >/dev/null
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${BUILD_SA}" \
  --role="roles/run.admin" >/dev/null

gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

gcloud builds submit "${BUILD_CONTEXT}" \
  --project="${PROJECT_ID}" \
  --config=cloudbuild.yaml \
  --substitutions="_SERVICE_NAME=${SERVICE_NAME},_REGION=${REGION},_AR_REPO=${AR_REPO},_DOCKERFILE=${DOCKERFILE},_BUILD_CONTEXT=${BUILD_CONTEXT},_TAG=${TAG},_APP_VERSION=${APP_VERSION}"

SERVICE_URL="$(gcloud run services describe "${SERVICE_NAME}" --project="${PROJECT_ID}" --region="${REGION}" --format='value(status.url)')"

printf '\nDeployment submitted.\n'
printf 'Service URL: %s\n' "${SERVICE_URL}"
printf 'Demo URL:    %s\n' "${DEMO_HOST}"
printf '\nSmoke checks:\n'
printf '  curl -I %s\n' "${DEMO_HOST}"
printf '  curl -s %s/health | jq .\n' "${SERVICE_URL}"
printf '  curl -s https://www.fractal5solutions.com/status | jq .\n'
printf '\nClaim-drift check:\n'
printf '  The live /demo page must not contain: All-green release evidence, Actual demo MP4 integrated, Open web MP4, Open master MP4.\n'
printf '  Only set all-green after demo1-public-proof and every #649 gate passes.\n'
