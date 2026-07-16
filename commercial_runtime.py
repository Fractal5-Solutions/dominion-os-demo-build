#!/usr/bin/env python3
"""Public receipt hardening wrapper for the Dominion OS demo runtime."""

from __future__ import annotations

import json
import os
from datetime import datetime, timezone

from flask import request

from command_core import app

PUBLIC_RECEIPT_PATHS = frozenset({
    "/health",
    "/healthz",
    "/ready",
    "/status",
    "/_ah/health",
})


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def runtime_revision(payload: dict) -> str:
    return (
        os.getenv("K_REVISION")
        or os.getenv("REVISION")
        or str(payload.get("revision") or "local")
    )


@app.after_request
def add_public_receipt_metadata(response):
    if request.path not in PUBLIC_RECEIPT_PATHS or not response.is_json:
        return response

    payload = response.get_json(silent=True)
    if not isinstance(payload, dict):
        return response

    generated_at = utc_now_iso()
    payload["generatedAt"] = generated_at
    payload["timestamp"] = generated_at
    payload["revision"] = runtime_revision(payload)
    payload["configuration"] = os.getenv("K_CONFIGURATION", "")
    payload["releaseCandidateSha"] = (
        os.getenv("RELEASE_SHA") or str(payload.get("release_sha") or "")
    )
    payload["receiptFreshnessSeconds"] = 0

    response.set_data(json.dumps(payload, ensure_ascii=True, separators=(",", ":")))
    response.headers["Content-Type"] = "application/json; charset=utf-8"
    response.headers["Cache-Control"] = "no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
    return response


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))
    app.run(host="0.0.0.0", port=port, debug=False)
