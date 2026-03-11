#!/usr/bin/env bash
set -euo pipefail

MANIFEST_PATH="${MANIFEST_PATH:-/workspaces/dominion-os-demo-build/deployments/cloud-run-services.dominion-core-prod.20260311.json}"
MODE="plan"
SERVICE_FILTER=""

usage() {
  cat <<'EOF'
Usage:
  scripts/deploy_all_cloud_run_from_manifest.sh [--plan] [--apply] [--service NAME]

Behavior:
  --plan           Print the exact gcloud commands for the manifest services.
  --apply          Execute the gcloud run deploy commands from the manifest.
  --service NAME   Limit to a single service.

Notes:
  - Uses the image already recorded in the manifest unless IMAGE_OVERRIDE_<SERVICE>
    is set in the environment, where <SERVICE> is uppercased and non-alnum becomes _.
  - Requires jq and gcloud auth with deploy permissions in the target project.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan)
      MODE="plan"
      shift
      ;;
    --apply)
      MODE="apply"
      shift
      ;;
    --service)
      SERVICE_FILTER="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$MANIFEST_PATH" ]]; then
  echo "Manifest not found: $MANIFEST_PATH" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

PROJECT_ID="$(jq -r '.project_id' "$MANIFEST_PATH")"
REGION="$(jq -r '.region' "$MANIFEST_PATH")"

if [[ "$MODE" == "apply" ]]; then
  gcloud config set project "$PROJECT_ID" --quiet >/dev/null
fi

jq -c '.services[]' "$MANIFEST_PATH" | while read -r service; do
  name="$(jq -r '.name' <<<"$service")"
  image="$(jq -r '.image' <<<"$service")"
  port="$(jq -r '.port' <<<"$service")"
  memory="$(jq -r '.memory' <<<"$service")"
  cpu="$(jq -r '.cpu' <<<"$service")"
  min_scale="$(jq -r '.min_scale // empty' <<<"$service")"
  max_scale="$(jq -r '.max_scale // empty' <<<"$service")"

  if [[ -n "$SERVICE_FILTER" && "$name" != "$SERVICE_FILTER" ]]; then
    continue
  fi

  override_key="$(printf '%s' "$name" | tr '[:lower:]-.' '[:upper:]__')"
  override_var="IMAGE_OVERRIDE_${override_key}"
  resolved_image="${!override_var:-$image}"

  cmd=(
    gcloud run deploy "$name"
    --project "$PROJECT_ID"
    --region "$REGION"
    --platform managed
    --image "$resolved_image"
    --allow-unauthenticated
    --port "$port"
    --memory "$memory"
    --cpu "$cpu"
  )

  if [[ -n "$min_scale" ]]; then
    cmd+=(--min-instances "$min_scale")
  fi
  if [[ -n "$max_scale" ]]; then
    cmd+=(--max-instances "$max_scale")
  fi

  if [[ "$MODE" == "plan" ]]; then
    printf '%q ' "${cmd[@]}"
    printf '\n'
  else
    echo "Deploying $name with image $resolved_image"
    "${cmd[@]}"
  fi
done
