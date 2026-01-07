#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HOOKS_DIR="$ROOT_DIR/tools/hooks"
GIT_HOOKS_DIR="$ROOT_DIR/.git/hooks"

mkdir -p "$GIT_HOOKS_DIR"

install_hook() {
  local name="$1"
  local src="$HOOKS_DIR/$name"
  local dest="$GIT_HOOKS_DIR/$name"
  if [[ -f "$src" ]]; then
    cp "$src" "$dest"
    chmod +x "$dest"
    echo "Installed $name"
  else
    echo "Skipping $name (not found)" >&2
  fi
}

install_hook post-merge
install_hook post-rewrite
install_hook post-checkout

echo "Git hooks installed into $GIT_HOOKS_DIR"
