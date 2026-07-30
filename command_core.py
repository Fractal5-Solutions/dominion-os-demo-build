from __future__ import annotations

import json
import os
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

import requests
from flask import Flask, abort, jsonify, render_template_string, request, send_from_directory

BASE_DIR = Path(__file__).resolve().parent
APP_START_MONOTONIC = time.monotonic()
DEFAULT_RELEASE_SHA = os.getenv("RELEASE_SHA", "unknown")
DEFAULT_RELEASE_VERSION = os.getenv("RELEASE_VERSION", DEFAULT_RELEASE_SHA[:12])
DEFAULT_SERVICE_NAME = os.getenv("K_SERVICE", os.getenv("SERVICE_NAME", "dominion-os-demo"))
DEFAULT_REGION = os.getenv("GOOGLE_CLOUD_REGION", os.getenv("REGION", "us-central1"))
REQUEST_TIMEOUT_SECONDS = max(0.25, float(os.getenv("REMOTE_REQUEST_TIMEOUT_SECONDS", "3")))
ALLOWED_REMOTE_SCHEMES = {"https"}

app = Flask(__name__)


LANDING_TEMPLATE = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Dominion OS Public Runtime</title>
  <style>
    :root { color-scheme: light; font-family: Arial, sans-serif; }
    body { margin: 0; background: #f6f7f9; color: #111827; }
    main { max-width: 920px; margin: 0 auto; padding: 48px 24px; }
    .panel { background: white; border: 1px solid #d8dde6; border-radius: 16px; padding: 28px; box-shadow: 0 10px 30px rgba(17,24,39,.08); }
    h1 { margin-top: 0; }
    a { color: #2357c6; }
    code { background: #eef1f6; padding: 2px 6px; border-radius: 5px; }
    ul { line-height: 1.7; }
  </style>
</head>
<body>
  <main>
    <section class="panel">
      <p><strong>{{ service }}</strong> · {{ region }}</p>
      <h1>Dominion OS public-safe reference runtime</h1>
      <p>This endpoint exposes only demonstration content, public receipts, and public-safe operating data.</p>
      <ul>
        <li><a href="/demo">Interactive demo</a></li>
        <li><a href="/health">Health receipt</a></li>
        <li><a href="/status">Status receipt</a></li>
      </ul>
      <p>Release: <code>{{ release_sha }}</code></p>
    </section>
  </main>
</body>
</html>
"""


DEMO_TEMPLATE = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Dominion OS Demo</title>
  <style>
    :root { color-scheme: light; font-family: Arial, sans-serif; }
    body { margin: 0; background: #f4f5f7; color: #101828; }
    main { max-width: 1080px; margin: 0 auto; padding: 40px 24px 64px; }
    .hero, .card { background: white; border: 1px solid #d8dde6; border-radius: 18px; padding: 26px; box-shadow: 0 12px 35px rgba(16,24,40,.08); }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(230px, 1fr)); gap: 18px; margin-top: 18px; }
    .card { box-shadow: none; }
    h1, h2 { margin-top: 0; }
    .status { display: inline-block; border-radius: 999px; padding: 6px 10px; background: #e8f7ee; color: #17653a; font-weight: 700; }
    code { background: #edf1f5; padding: 2px 6px; border-radius: 5px; word-break: break-all; }
    a { color: #2357c6; }
  </style>
</head>
<body>
  <main>
    <section class="hero">
      <span class="status">Public-safe reference runtime</span>
      <h1>Dominion OS live demonstration surface</h1>
      <p>Inspect a governed runtime, public evidence, and bounded example operations without exposing private client data or private services.</p>
      <p>Release: <code>{{ release_sha }}</code></p>
    </section>
    <section class="grid">
      <article class="card">
        <h2>Runtime health</h2>
        <p><a href="/health">Open the current health receipt</a>.</p>
      </article>
      <article class="card">
        <h2>Operating status</h2>
        <p><a href="/status">Open the public status receipt</a>.</p>
      </article>
      <article class="card">
        <h2>Sample operations</h2>
        <p><a href="/demo/assets/sample-data.json">Open the public-safe sample payload</a>.</p>
      </article>
    </section>
  </main>
</body>
</html>
"""


PROJECTS: list[dict[str, Any]] = [
    {
        "name": "Dominion OS public reference runtime",
        "status": "ready",
        "scope": "public-safe runtime and receipts",
    },
    {
        "name": "Multi-cloud deployment contract",
        "status": "ready",
        "scope": "Google Cloud, Azure, AWS, and Oracle Cloud deployment readiness",
    },
    {
        "name": "Client boundary model",
        "status": "ready",
        "scope": "client-owned identity, network, data, keys, and policy",
    },
]


@app.after_request
def add_security_headers(response):
    response.headers.setdefault("X-Content-Type-Options", "nosniff")
    response.headers.setdefault("X-Frame-Options", "DENY")
    response.headers.setdefault("Referrer-Policy", "strict-origin-when-cross-origin")
    response.headers.setdefault("Permissions-Policy", "camera=(), microphone=(), geolocation=()")
    response.headers.setdefault("Cross-Origin-Opener-Policy", "same-origin")
    response.headers.setdefault(
        "Content-Security-Policy",
        "default-src 'self'; "
        "img-src 'self' data:; "
        "media-src 'self'; "
        "style-src 'self' 'unsafe-inline'; "
        "script-src 'self' 'unsafe-inline'; "
        "font-src 'self' data:; "
        "connect-src 'self'; "
        "base-uri 'self'; "
        "frame-ancestors 'none'; "
        "form-action 'self' mailto:",
    )

    if request.path.startswith("/demo/assets/media/"):
        response.headers["Cache-Control"] = "public, max-age=31536000, immutable"
    elif request.path.startswith("/demo/assets/"):
        response.headers["Cache-Control"] = "public, max-age=300"
    elif request.path.startswith("/api/") or request.path in {
        "/health",
        "/healthz",
        "/ready",
        "/status",
        "/demo/status",
        "/_ah/health",
    }:
        response.headers["Cache-Control"] = "no-store, max-age=0, must-revalidate"

    return response


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def iso_timestamp() -> str:
    return utc_now().isoformat().replace("+00:00", "Z")


def release_sha() -> str:
    return os.getenv("RELEASE_SHA", DEFAULT_RELEASE_SHA)


def release_version() -> str:
    return os.getenv("RELEASE_VERSION", DEFAULT_RELEASE_VERSION)


def service_info() -> dict[str, Any]:
    return {
        "service": os.getenv("K_SERVICE", DEFAULT_SERVICE_NAME),
        "region": os.getenv("GOOGLE_CLOUD_REGION", DEFAULT_REGION),
        "releaseCandidateSha": release_sha(),
        "releaseVersion": release_version(),
        "generatedAt": iso_timestamp(),
        "uptimeSeconds": round(max(0.0, time.monotonic() - APP_START_MONOTONIC), 3),
    }


def wants_json_response() -> bool:
    accepted = request.accept_mimetypes
    return accepted["application/json"] > accepted["text/html"]


def safe_remote_url(raw_url: str) -> str | None:
    try:
        parsed = urlparse(raw_url)
    except ValueError:
        return None
    if parsed.scheme not in ALLOWED_REMOTE_SCHEMES or not parsed.netloc:
        return None
    if parsed.username or parsed.password:
        return None
    return parsed.geturl()


def load_remote_projects() -> list[dict[str, Any]]:
    raw_url = os.getenv("REMOTE_PROJECTS_URL", "").strip()
    remote_url = safe_remote_url(raw_url)
    if not remote_url:
        return PROJECTS

    try:
        response = requests.get(remote_url, timeout=REQUEST_TIMEOUT_SECONDS)
        response.raise_for_status()
        payload = response.json()
    except (requests.RequestException, ValueError):
        return PROJECTS

    if isinstance(payload, list):
        return [item for item in payload if isinstance(item, dict)] or PROJECTS
    if isinstance(payload, dict):
        projects = payload.get("projects")
        if isinstance(projects, list):
            return [item for item in projects if isinstance(item, dict)] or PROJECTS
    return PROJECTS


def send_static_page(directory: str):
    allowed_dirs = {"demo", "store"}
    if directory not in allowed_dirs:
        abort(404)
    return send_from_directory(str(BASE_DIR / directory), "index.html")


@app.route("/")
def index():
    info = service_info()
    if wants_json_response() or request.args.get("format") == "json":
        return jsonify(info)

    remote_projects = load_remote_projects()
    return render_template_string(
        LANDING_TEMPLATE,
        service=info["service"],
        region=info["region"],
        release_sha=info["releaseCandidateSha"],
        projects=remote_projects,
    )


@app.route("/demo")
def demo():
    demo_index = BASE_DIR / "demo" / "index.html"
    if demo_index.exists():
        return send_static_page("demo")
    return render_template_string(DEMO_TEMPLATE, release_sha=release_sha())


@app.route("/store")
def store():
    store_index = BASE_DIR / "store" / "index.html"
    if store_index.exists():
        return send_static_page("store")
    abort(404)


@app.route("/demo/assets/<path:filename>")
def demo_asset(filename: str):
    return send_from_directory(str(BASE_DIR / "demo" / "assets"), filename)


@app.route("/api/projects")
def api_projects():
    return jsonify({"projects": load_remote_projects(), "generatedAt": iso_timestamp()})


def receipt_payload(state: str = "healthy") -> dict[str, Any]:
    info = service_info()
    return {
        "ok": state in {"healthy", "ready"},
        "status": state,
        "service": info["service"],
        "region": info["region"],
        "releaseCandidateSha": info["releaseCandidateSha"],
        "releaseVersion": info["releaseVersion"],
        "generatedAt": info["generatedAt"],
        "uptimeSeconds": info["uptimeSeconds"],
        "publicSafe": True,
        "privateServicesExposed": False,
    }


@app.route("/health")
@app.route("/healthz")
@app.route("/_ah/health")
def health():
    return jsonify(receipt_payload("healthy"))


@app.route("/ready")
def ready():
    return jsonify(receipt_payload("ready"))


@app.route("/status")
@app.route("/demo/status")
def status():
    payload = receipt_payload("healthy")
    payload.update(
        {
            "deploymentReady": True,
            "supportedEstates": [
                "Google Cloud",
                "Microsoft Azure",
                "Amazon Web Services",
                "Oracle Cloud Infrastructure",
            ],
            "publicRuntimeDependency": False,
        }
    )
    return jsonify(payload)


@app.errorhandler(404)
def not_found(_error):
    return jsonify({"ok": False, "error": "not_found", "path": request.path}), 404


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
