#!/usr/bin/env bash
set -euo pipefail

# PHI Intelligent Sync
# Local-first sync with branch-aware push, lock protection, and retry logic.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TELEMETRY_DIR="${SCRIPT_DIR}/telemetry"
LOG="${TELEMETRY_DIR}/intelligent_sync.log"
LOCK_FILE="${TELEMETRY_DIR}/intelligent_sync.lock"

SYNC_REMOTE="${PHI_SYNC_REMOTE:-origin}"
SYNC_BRANCH="${PHI_SYNC_BRANCH:-}"
SYNC_MAX_RETRIES="${PHI_SYNC_MAX_RETRIES:-3}"
SYNC_RETRY_SECONDS="${PHI_SYNC_RETRY_SECONDS:-2}"

mkdir -p "${TELEMETRY_DIR}"

log() {
  printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$1" >> "${LOG}"
}

with_lock_or_exit() {
  exec 9>"${LOCK_FILE}"
  if command -v flock >/dev/null 2>&1; then
    if ! flock -n 9; then
      log "Sync skipped: another intelligent sync process is active"
      exit 0
    fi
  fi
}

is_https_remote() {
  local remote_url="$1"
  [[ "${remote_url}" =~ ^https:// ]]
}

detect_token() {
  local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
  local token_line

  if [ -n "${token}" ]; then
    printf '%s\n' "${token}"
    return
  fi

  if [ -f "${HOME}/.git-credentials" ]; then
    token_line="$(grep -m1 "github.com" "${HOME}/.git-credentials" || true)"
    token="$(printf '%s' "${token_line}" | sed -n 's|https://[^:]*:\([^@]*\)@github.com.*|\1|p')"
  fi

  printf '%s\n' "${token:-}"
}

push_with_retry() {
  local push_remote="$1"
  local target_branch="$2"
  local attempt=1

  while [ "${attempt}" -le "${SYNC_MAX_RETRIES}" ]; do
    if git push "${push_remote}" "HEAD:${target_branch}" >> "${LOG}" 2>&1; then
      log "Push successful to ${target_branch} on attempt ${attempt}"
      return 0
    fi

    if [ "${attempt}" -lt "${SYNC_MAX_RETRIES}" ]; then
      local backoff=$(( SYNC_RETRY_SECONDS * attempt ))
      log "Push attempt ${attempt} failed; retrying in ${backoff}s"
      sleep "${backoff}"
    fi

    attempt=$((attempt + 1))
  done

  log "Push failed after ${SYNC_MAX_RETRIES} attempts"
  return 1
}

main() {
  with_lock_or_exit

  cd "${REPO_DIR}" || exit 1

  log "Intelligent sync start"

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log "Sync aborted: ${REPO_DIR} is not a git repository"
    exit 1
  fi

  if ! git remote get-url "${SYNC_REMOTE}" >/dev/null 2>&1; then
    log "Sync aborted: git remote '${SYNC_REMOTE}' is not configured"
    exit 1
  fi

  local current_branch
  current_branch="$(git rev-parse --abbrev-ref HEAD)"

  if [ -z "${SYNC_BRANCH}" ]; then
    SYNC_BRANCH="${current_branch}"
  fi

  git fetch "${SYNC_REMOTE}" >> "${LOG}" 2>&1 || log "Fetch warning: unable to refresh ${SYNC_REMOTE}"

  if ! git diff --quiet || ! git diff --cached --quiet; then
    git add -A
    git commit -m "PHI intelligent sync: $(date -u +'%Y-%m-%dT%H:%M:%SZ')" >> "${LOG}" 2>&1 || true
  fi

  local remote_ref="refs/remotes/${SYNC_REMOTE}/${SYNC_BRANCH}"
  local commits_ahead

  if git show-ref --verify --quiet "${remote_ref}"; then
    commits_ahead="$(git rev-list --count "${SYNC_REMOTE}/${SYNC_BRANCH}..HEAD" 2>/dev/null || echo 0)"
  else
    commits_ahead="$(git rev-list --count HEAD 2>/dev/null || echo 0)"
    log "Remote branch ${SYNC_BRANCH} not found; preparing initial push"
  fi

  if [ "${commits_ahead}" -eq 0 ]; then
    log "No commits to push for ${SYNC_BRANCH}"
    exit 0
  fi

  log "Commits ahead on ${SYNC_BRANCH}: ${commits_ahead}"

  local remote_url
  remote_url="$(git remote get-url "${SYNC_REMOTE}")"

  if is_https_remote "${remote_url}"; then
    local token
    token="$(detect_token)"

    if [ -z "${token}" ]; then
      log "HTTPS remote detected but no GitHub token available; push deferred"
      exit 0
    fi

    local auth_remote
    auth_remote="$(printf '%s' "${remote_url}" | sed -E "s#https://#https://${token}:@#")"
    push_with_retry "${auth_remote}" "${SYNC_BRANCH}" || exit 1
  else
    push_with_retry "${SYNC_REMOTE}" "${SYNC_BRANCH}" || exit 1
  fi

  log "Intelligent sync finished"
}

main "$@"
