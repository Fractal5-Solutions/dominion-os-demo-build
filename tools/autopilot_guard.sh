#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-preflight}"

fail() {
  echo "[guard][error] $*" >&2
  exit 1
}

ensure_not_root() {
  if [ "$(id -u)" -eq 0 ]; then
    fail "Do not run autopilot as root; use a normal user so HOME/ssh/gh/gcloud config is available."
  fi
}

ensure_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "Not inside a git repository."
}

ensure_upstream() {
  git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1 || fail "No upstream configured for current branch."
}

preflight() {
  ensure_not_root
  ensure_git_repo
  git fetch --prune
  if [ -n "$(git status --porcelain)" ]; then
    fail "Working tree not clean. Commit/stash changes before autopilot."
  fi
  ensure_upstream
  counts=$(git rev-list --left-right --count @{u}...HEAD)
  behind=${counts%% *}
  ahead=${counts##* }
  if [ "$behind" -ne 0 ] || [ "$ahead" -ne 0 ]; then
    fail "Branch not synchronized with upstream (behind=${behind}, ahead=${ahead})."
  fi
  tmp=$(mktemp)
  if ! git push --porcelain --dry-run 2>"$tmp"; then
    echo "[guard][error] Dry-run push failed; aborting before commits." >&2
    tail -n 50 "$tmp" >&2 || true
    rm -f "$tmp"
    exit 1
  fi
  rm -f "$tmp"
  echo "[guard][ok] Preflight checks passed."
}

push_or_abort() {
  ensure_not_root
  ensure_git_repo
  ensure_upstream
  counts=$(git rev-list --left-right --count @{u}...HEAD)
  behind=${counts%% *}
  ahead=${counts##* }
  if [ "$behind" -ne 0 ]; then
    fail "Upstream is ahead by ${behind}; pull/rebase before pushing."
  fi
  if [ "$ahead" -eq 0 ]; then
    echo "[guard][ok] No commits to push."
    return 0
  fi
  tmp=$(mktemp)
  if ! git push --porcelain 2>"$tmp"; then
    mkdir -p out/autopilot
    {
      echo "git status -sb"
      git status -sb
      echo ""
      echo "push stderr (last 50 lines):"
      tail -n 50 "$tmp" || true
      echo ""
      echo "auth diagnostics:"
      if git remote -v | grep -qE '^origin[[:space:]]+git@github.com:'; then
        ssh -T git@github.com || true
      fi
      if command -v gh >/dev/null 2>&1; then
        gh auth status || true
      fi
    } > out/autopilot/push-failure.txt
    cat out/autopilot/push-failure.txt >&2
    rm -f "$tmp"
    exit 1
  fi
  rm -f "$tmp"
  echo "[guard][ok] Push succeeded."
}

case "$MODE" in
  preflight)
    preflight
    ;;
  push-or-abort)
    push_or_abort
    ;;
  *)
    echo "Usage: $0 preflight|push-or-abort" >&2
    exit 2
    ;;
esac
