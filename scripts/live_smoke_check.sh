#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <base_url> [base_url...]" >&2
  echo "Env:" >&2
  echo "  SMOKE_AUTH=1                    Use gcloud ID token per base URL" >&2
  echo "  SMOKE_AUTH_SA=<service-account> Use SA impersonation for ID token" >&2
  echo "  SMOKE_AUTH_TOKEN=<token>        Reuse a pre-generated bearer token" >&2
  echo "  EXPECTED_HEALTH_CODES=200,401   Comma-separated acceptable /health status codes" >&2
  echo "  EXPECTED_READY_CODES=200,401    Comma-separated acceptable /ready status codes" >&2
  exit 1
fi

EXPECTED_HEALTH_CODES="${EXPECTED_HEALTH_CODES:-200}"
EXPECTED_READY_CODES="${EXPECTED_READY_CODES:-200}"
SMOKE_AUTH="${SMOKE_AUTH:-0}"
SMOKE_AUTH_SA="${SMOKE_AUTH_SA:-}"
SMOKE_AUTH_TOKEN="${SMOKE_AUTH_TOKEN:-}"

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

status_allowed() {
  local actual="$1"
  local allowed_csv="$2"
  IFS=',' read -r -a allowed <<< "$allowed_csv"
  for code in "${allowed[@]}"; do
    code="$(echo "$code" | xargs)"
    if [[ "$actual" == "$code" ]]; then
      return 0
    fi
  done
  return 1
}

id_token_for_audience() {
  local audience="$1"
  if [[ -n "$SMOKE_AUTH_TOKEN" ]]; then
    echo "$SMOKE_AUTH_TOKEN"
    return 0
  fi
  if [[ -n "$SMOKE_AUTH_SA" ]]; then
    gcloud auth print-identity-token --impersonate-service-account="$SMOKE_AUTH_SA" --audiences="$audience" 2>/dev/null || true
    return 0
  fi
  gcloud auth print-identity-token --audiences="$audience" 2>/dev/null || true
}

check_endpoint() {
  local url="$1"
  local expected_csv="$2"
  local auth_header="$3"
  local headers
  local body
  headers="$(mktemp)"
  body="$(mktemp)"
  local status
  local curl_args=(-sS -o "$body" -D "$headers" -w '%{http_code}')
  if [[ -n "$auth_header" ]]; then
    curl_args+=(-H "$auth_header")
  fi
  status="$(curl "${curl_args[@]}" "$url" || true)"

  if ! status_allowed "$status" "$expected_csv"; then
    if [[ "$status" == "404" ]] && grep -qi "server: Google Frontend" "$headers"; then
      echo "[FAIL] ${url} expected {${expected_csv}}, got ${status} (possible private ingress or route mismatch)"
    else
      echo "[FAIL] ${url} expected {${expected_csv}}, got ${status}"
    fi
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

  auth_header=""
  if [[ "$SMOKE_AUTH" == "1" ]]; then
    token="$(id_token_for_audience "$base")"
    if [[ -n "$token" ]]; then
      auth_header="Authorization: Bearer ${token}"
      echo "[INFO] Auth token acquired for ${base}"
    else
      echo "[WARN] Failed to acquire auth token for ${base}; probing unauthenticated"
    fi
  fi

  check_tls "$host" || overall=1
  check_endpoint "${base}/health" "$EXPECTED_HEALTH_CODES" "$auth_header" || overall=1
  check_endpoint "${base}/ready" "$EXPECTED_READY_CODES" "$auth_header" || overall=1
done

if [[ "$overall" -ne 0 ]]; then
  echo "Smoke checks failed."
  exit 1
fi

echo "All smoke checks passed."
