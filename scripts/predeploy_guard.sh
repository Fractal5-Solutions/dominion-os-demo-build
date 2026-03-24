#!/usr/bin/env bash
set -euo pipefail

required_vars=(
  "JWT_SECRET"
  "SESSION_SECRET"
  "GITHUB_CLIENT_ID"
  "GITHUB_CLIENT_SECRET"
)

placeholder_patterns=(
  '^$'
  '^change[-_ ]?me$'
  '^change_this$'
  '^your_.*_here$'
  '^placeholder$'
)

is_placeholder() {
  local value="$1"
  local lowered
  lowered="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]' | xargs)"
  for pattern in "${placeholder_patterns[@]}"; do
    if [[ "$lowered" =~ $pattern ]]; then
      return 0
    fi
  done
  return 1
}

failed=0
for key in "${required_vars[@]}"; do
  value="${!key:-}"
  if is_placeholder "$value"; then
    echo "[FAIL] $key is missing or placeholder-like" >&2
    failed=1
  else
    echo "[OK] $key present"
  fi
done

if [[ "$failed" -ne 0 ]]; then
  echo "Predeploy guard failed. Inject real secrets before deploy." >&2
  exit 1
fi

echo "Predeploy guard passed."
