#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-f5-prod-command-core}"
PROJECT_NUMBER="${PROJECT_NUMBER:-732190342674}"
LOCATION="${LOCATION:-global}"
POOL_ID="${POOL_ID:-fractal5-github-pool}"
PROVIDER_ID="${PROVIDER_ID:-github-provider}"
SERVICE_ACCOUNT="${SERVICE_ACCOUNT:-dominion-demo-oidc-sa@f5-prod-command-core.iam.gserviceaccount.com}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY_TARGET:-Fractal5-Solutions/dominion-os-demo-build}"
APPLY="${APPLY_WIF_RESTORE:-false}"
ISSUER_URI="https://token.actions.githubusercontent.com"
ATTRIBUTE_MAPPING="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner,attribute.ref=assertion.ref"
ATTRIBUTE_CONDITION="assertion.repository == '${GITHUB_REPOSITORY}' && (assertion.ref == 'refs/heads/main' || assertion.ref.startsWith('refs/tags/v'))"
POOL_RESOURCE="projects/${PROJECT_NUMBER}/locations/${LOCATION}/workloadIdentityPools/${POOL_ID}"
PROVIDER_RESOURCE="${POOL_RESOURCE}/providers/${PROVIDER_ID}"
MEMBER="principalSet://iam.googleapis.com/${POOL_RESOURCE}/attribute.repository/${GITHUB_REPOSITORY}"

log() { printf '%s\n' "$*"; }
die() { log "ERROR: $*" >&2; exit 1; }

need_gcloud() {
  command -v gcloud >/dev/null 2>&1 || die "gcloud CLI is not installed or not on PATH."
}

active_account() {
  gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null | head -n 1
}

resource_state() {
  local kind="$1"
  local id="$2"
  if [ "$kind" = "pool" ]; then
    gcloud iam workload-identity-pools describe "$id" \
      --project="$PROJECT_ID" --location="$LOCATION" \
      --format='value(state)' 2>/dev/null || true
  else
    gcloud iam workload-identity-pools providers describe "$id" \
      --project="$PROJECT_ID" --location="$LOCATION" \
      --workload-identity-pool="$POOL_ID" \
      --format='value(state)' 2>/dev/null || true
  fi
}

deleted_state() {
  local kind="$1"
  local id="$2"
  if [ "$kind" = "pool" ]; then
    gcloud iam workload-identity-pools list \
      --project="$PROJECT_ID" --location="$LOCATION" --show-deleted \
      --filter="name:${POOL_RESOURCE}" --format='value(state)' 2>/dev/null | head -n 1
  else
    gcloud iam workload-identity-pools providers list \
      --project="$PROJECT_ID" --location="$LOCATION" \
      --workload-identity-pool="$POOL_ID" --show-deleted \
      --filter="name:${PROVIDER_RESOURCE}" --format='value(state)' 2>/dev/null | head -n 1
  fi
}

wait_active() {
  local kind="$1"
  local id="$2"
  local attempt state
  for attempt in $(seq 1 60); do
    state="$(resource_state "$kind" "$id")"
    if [ "$state" = "ACTIVE" ]; then
      return 0
    fi
    sleep 5
  done
  die "${kind} ${id} did not become ACTIVE within the verification window."
}

ensure_pool() {
  local state deleted
  state="$(resource_state pool "$POOL_ID")"
  if [ "$state" = "ACTIVE" ]; then
    log "POOL: ACTIVE"
    return 0
  fi

  if [ "$APPLY" != "true" ]; then
    deleted="$(deleted_state pool "$POOL_ID")"
    if [ "$deleted" = "DELETED" ]; then
      log "POOL: DELETED -> would undelete and enable ${POOL_ID}"
    elif [ -n "$state" ]; then
      log "POOL: ${state} -> would enable ${POOL_ID}"
    else
      log "POOL: MISSING -> would create ${POOL_ID}"
    fi
    return 0
  fi

  deleted="$(deleted_state pool "$POOL_ID")"
  if [ "$deleted" = "DELETED" ]; then
    log "Restoring deleted pool ${POOL_ID}"
    gcloud iam workload-identity-pools undelete "$POOL_ID" \
      --project="$PROJECT_ID" --location="$LOCATION" --quiet
  elif [ -z "$state" ]; then
    log "Creating pool ${POOL_ID}"
    gcloud iam workload-identity-pools create "$POOL_ID" \
      --project="$PROJECT_ID" --location="$LOCATION" \
      --display-name="Fractal5 GitHub Actions" --quiet
  fi

  gcloud iam workload-identity-pools update "$POOL_ID" \
    --project="$PROJECT_ID" --location="$LOCATION" --no-disabled --quiet
  wait_active pool "$POOL_ID"
  log "POOL: ACTIVE"
}

ensure_provider() {
  local state deleted
  state="$(resource_state provider "$PROVIDER_ID")"
  if [ "$APPLY" != "true" ]; then
    if [ "$state" = "ACTIVE" ]; then
      log "PROVIDER: ACTIVE -> would reconcile issuer, mappings, condition and enabled state"
    else
      deleted="$(deleted_state provider "$PROVIDER_ID")"
      if [ "$deleted" = "DELETED" ]; then
        log "PROVIDER: DELETED -> would undelete and reconcile ${PROVIDER_ID}"
      elif [ -n "$state" ]; then
        log "PROVIDER: ${state} -> would enable and reconcile ${PROVIDER_ID}"
      else
        log "PROVIDER: MISSING -> would create ${PROVIDER_ID}"
      fi
    fi
    return 0
  fi

  deleted="$(deleted_state provider "$PROVIDER_ID")"
  if [ "$deleted" = "DELETED" ]; then
    log "Restoring deleted provider ${PROVIDER_ID}"
    gcloud iam workload-identity-pools providers undelete "$PROVIDER_ID" \
      --project="$PROJECT_ID" --location="$LOCATION" \
      --workload-identity-pool="$POOL_ID" --quiet
    wait_active provider "$PROVIDER_ID"
    state="ACTIVE"
  fi

  if [ -z "$state" ] && [ "$deleted" != "DELETED" ]; then
    log "Creating provider ${PROVIDER_ID}"
    gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_ID" \
      --project="$PROJECT_ID" --location="$LOCATION" \
      --workload-identity-pool="$POOL_ID" \
      --display-name="Fractal5 GitHub Actions" \
      --issuer-uri="$ISSUER_URI" \
      --attribute-mapping="$ATTRIBUTE_MAPPING" \
      --attribute-condition="$ATTRIBUTE_CONDITION" \
      --quiet
  else
    log "Reconciling provider ${PROVIDER_ID}"
    gcloud iam workload-identity-pools providers update-oidc "$PROVIDER_ID" \
      --project="$PROJECT_ID" --location="$LOCATION" \
      --workload-identity-pool="$POOL_ID" \
      --no-disabled \
      --issuer-uri="$ISSUER_URI" \
      --attribute-mapping="$ATTRIBUTE_MAPPING" \
      --attribute-condition="$ATTRIBUTE_CONDITION" \
      --quiet
  fi

  wait_active provider "$PROVIDER_ID"
  log "PROVIDER: ACTIVE"
}

binding_present() {
  gcloud iam service-accounts get-iam-policy "$SERVICE_ACCOUNT" \
    --project="$PROJECT_ID" --format=json 2>/dev/null | \
    python -c 'import json,sys; d=json.load(sys.stdin); role="roles/iam.workloadIdentityUser"; member=sys.argv[1]; print("true" if any(b.get("role")==role and member in b.get("members",[]) for b in d.get("bindings",[])) else "false")' "$MEMBER"
}

ensure_binding() {
  gcloud iam service-accounts describe "$SERVICE_ACCOUNT" \
    --project="$PROJECT_ID" --format='value(email)' >/dev/null 2>&1 || \
    die "Dedicated deployment service account does not exist: ${SERVICE_ACCOUNT}. Refusing to create or substitute an identity automatically."

  if [ "$(binding_present)" = "true" ]; then
    log "SERVICE ACCOUNT BINDING: PRESENT"
    return 0
  fi

  if [ "$APPLY" != "true" ]; then
    log "SERVICE ACCOUNT BINDING: MISSING -> would add repository-scoped roles/iam.workloadIdentityUser"
    return 0
  fi

  log "Adding repository-scoped Workload Identity User binding"
  gcloud iam service-accounts add-iam-policy-binding "$SERVICE_ACCOUNT" \
    --project="$PROJECT_ID" \
    --role="roles/iam.workloadIdentityUser" \
    --member="$MEMBER" \
    --quiet >/dev/null

  [ "$(binding_present)" = "true" ] || die "Workload Identity User binding did not verify after mutation."
  log "SERVICE ACCOUNT BINDING: PRESENT"
}

main() {
  need_gcloud
  local account actual_number
  account="$(active_account)"
  [ -n "$account" ] || die "No active gcloud account. Authenticate an authorized Google Cloud owner/operator session first."

  actual_number="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)' 2>/dev/null || true)"
  [ "$actual_number" = "$PROJECT_NUMBER" ] || die "Project identity mismatch: ${PROJECT_ID} resolved to '${actual_number}', expected '${PROJECT_NUMBER}'."

  log "GCloud WIF restoration contract"
  log "  active_account=${account}"
  log "  project=${PROJECT_ID}"
  log "  project_number=${PROJECT_NUMBER}"
  log "  pool=${POOL_ID}"
  log "  provider=${PROVIDER_ID}"
  log "  repository=${GITHUB_REPOSITORY}"
  log "  apply=${APPLY}"
  log

  ensure_pool
  ensure_provider
  ensure_binding

  log
  if [ "$APPLY" = "true" ]; then
    log "RESTORE RESULT: provider-side WIF contract reconciled."
    log "NEXT GATE: rerun the repository GCloud WIF Auth Probe and require its receipt to show AUTHENTICATED/pass=true before enabling deployment."
  else
    log "INSPECTION RESULT: no cloud mutation attempted."
    log "To apply only the bounded WIF restoration after reviewing this plan: APPLY_WIF_RESTORE=true bash ops/gcloud/restore_github_wif.sh"
  fi
}

main "$@"
