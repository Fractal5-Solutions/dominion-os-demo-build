#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <base_url> [base_url...]" >&2
  exit 1
fi

check_tls() {
  local host="$1"
  local cert_dates
  cert_dates="$(echo | openssl s_client -connect "${host}:443" -servername "${host}" 2>/dev/null | openssl x509 -noout -dates)"
  if [[ -z "$cert_dates" ]]; then
    echo "[FAIL] TLS cert read failed for ${host}"
    return 1
  fi
  echo "[OK] TLS ${host} -> ${cert_dates//$'\n'/, }"
}

check_endpoint() {
  local url="$1"
  local expected="$2"
  local headers
  local body
  headers="$(mktemp)"
  body="$(mktemp)"
  local status
  status="$(curl -sS -o "$body" -D "$headers" -w '%{http_code}' "$url" || true)"
  if [[ "$status" != "$expected" ]]; then
    echo "[FAIL] ${url} expected ${expected}, got ${status}"
    rm -f "$headers" "$body"
    return 1
  fi
  if grep -qi "x-cloud-trace-context\|server: Google Frontend" "$headers"; then
    echo "[OK] ${url} status=${status} (cloud-run header detected)"
  else
    echo "[WARN] ${url} status=${status} (no cloud-run header detected)"
  fi
  rm -f "$headers" "$body"
}

overall=0
for base in "$@"; do
  base="${base%/}"
  host="$(echo "$base" | sed -E 's#^https?://##')"
  echo "== Smoke: ${base} =="

  check_tls "$host" || overall=1
  check_endpoint "${base}/health" "200" || overall=1
  check_endpoint "${base}/ready" "200" || overall=1
done

if [[ "$overall" -ne 0 ]]; then
  echo "Smoke checks failed."
  exit 1
fi

echo "All smoke checks passed."
