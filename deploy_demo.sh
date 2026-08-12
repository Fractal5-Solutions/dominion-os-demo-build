#!/usr/bin/env bash
set -euo pipefail

# Canonical public-demo deployment is GitHub OIDC via .github/workflows/cicd-deploy.yml.
# This local script is retained only as an explicitly gated recovery path.
PROJECT_ID="${PROJECT_ID:-f5-prod-command-core}"
PROJECT_NUMBER="${PROJECT_NUMBER:-732190342674}"
REGION="${REGION:-us-central1}"
SERVICE_NAME="${SERVICE_NAME:-demo}"
AR_REPO="${AR_REPO:-dominion-demo-repo}"
DOCKERFILE="${DOCKERFILE:-Dockerfile.production}"
BUILD_CONTEXT="${BUILD_CONTEXT:-.}"
TAG="${TAG:-latest}"
PUBLIC_DEMO_BASE_URL="${PUBLIC_DEMO_BASE_URL:-https://demo-reduwyf2ra-uc.a.run.app}"
ALLOW_MUTATING_LOCAL_DEPLOY="${ALLOW_MUTATING_LOCAL_DEPLOY:-false}"

echo "== Fractal5 Demo Deploy Recovery Path =="
echo "Project ID:      ${PROJECT_ID}"
echo "Project number:  ${PROJECT_NUMBER}"
echo "Region:          ${REGION}"
echo "Service:         ${SERVICE_NAME}"
echo "Image:           ${REGION}-docker.pkg.dev/${PROJECT_ID}/${AR_REPO}/${SERVICE_NAME}:${TAG}"
echo

echo "Canonical deployment path: GitHub Actions OIDC (.github/workflows/cicd-deploy.yml)"
echo "This local script is fail-closed by default."

if [ "${ALLOW_MUTATING_LOCAL_DEPLOY}" != "true" ]; then
  echo
  echo "WITHHELD: local mutation is disabled."
  echo "Set ALLOW_MUTATING_LOCAL_DEPLOY=true only for an explicitly authorized recovery deployment."
  echo "No APIs, IAM bindings, Artifact Registry repositories, builds, or Cloud Run services were changed."
  exit 3
fi

if ! gcloud auth list --filter=status:ACTIVE --format='value(account)' | grep -q .; then
  echo "ERROR: no active gcloud identity found."
  exit 1
fi

ACTUAL_PROJECT_NUMBER="$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')"
if [ "${ACTUAL_PROJECT_NUMBER}" != "${PROJECT_NUMBER}" ]; then
  echo "ERROR: project identity mismatch. Expected ${PROJECT_NUMBER}; got ${ACTUAL_PROJECT_NUMBER}."
  exit 1
fi

gcloud config set project "${PROJECT_ID}" >/dev/null

# Do not create or broaden IAM bindings here. The recovery path requires the
# necessary least-privilege permissions to exist already. Provider/IAM repair
# belongs to an authenticated Google Cloud owner session and must be receipt-backed.
if ! gcloud artifacts repositories describe "${AR_REPO}" --project="${PROJECT_ID}" --location="${REGION}" >/dev/null 2>&1; then
  echo "ERROR: Artifact Registry repository ${AR_REPO} is absent. Refusing to create it from the recovery script."
  exit 1
fi

gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

gcloud builds submit "${BUILD_CONTEXT}" \
  --project="${PROJECT_ID}" \
  --config=cloudbuild.yaml \
  --substitutions="_SERVICE_NAME=${SERVICE_NAME},_REGION=${REGION},_AR_REPO=${AR_REPO},_DOCKERFILE=${DOCKERFILE},_BUILD_CONTEXT=${BUILD_CONTEXT},_TAG=${TAG},_APP_VERSION=${TAG}"

SERVICE_URL="$(gcloud run services describe "${SERVICE_NAME}" --project="${PROJECT_ID}" --region="${REGION}" --format='value(status.url)')"

echo
echo "Recovery deployment submitted."
echo "Service URL: ${SERVICE_URL}"
echo "Required verification:"
echo "  ${PUBLIC_DEMO_BASE_URL}/demo"
echo "  ${PUBLIC_DEMO_BASE_URL}/health"
echo "  ${PUBLIC_DEMO_BASE_URL}/status"
echo "Do not claim runtime GREEN until the exact-release receipt passes."
