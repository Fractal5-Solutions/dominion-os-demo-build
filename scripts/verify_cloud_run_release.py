#!/usr/bin/env python3
"""Verify live Cloud Run release metadata against the expected repo state."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request


def run_cmd(args: list[str]) -> str:
    candidates = [args]
    if os.name == "nt" and args and args[0] == "gcloud":
        candidates.append(["gcloud.cmd", *args[1:]])

    last_error: Exception | None = None
    for candidate in candidates:
        try:
            return subprocess.check_output(candidate, text=True).strip()
        except FileNotFoundError as exc:
            last_error = exc
            continue

    raise SystemExit(
        f"unable to execute command '{args[0]}'; ensure gcloud CLI is available on PATH"
    ) from last_error


def fetch_json(url: str, headers: dict[str, str] | None = None) -> dict:
    request = urllib.request.Request(url, headers=headers or {})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.loads(response.read().decode("utf-8"))


def assert_equal(actual: str, expected: str, label: str) -> None:
    if actual != expected:
        raise SystemExit(f"{label} mismatch: expected '{expected}', got '{actual}'")


def image_ref_matches_expected_prefix(image_ref: str, expected_prefix: str) -> bool:
    if image_ref.startswith(expected_prefix):
        return True

    # Cloud Run may preserve tag notation (:) even when callers expect digest notation (@).
    if expected_prefix.endswith("@") and image_ref.startswith(f"{expected_prefix[:-1]}:"):
        return True

    return False


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True)
    parser.add_argument("--region", required=True)
    parser.add_argument("--service", required=True)
    parser.add_argument("--expected-image-prefix", required=True)
    parser.add_argument("--expected-version", required=True)
    parser.add_argument("--expected-overlay", required=True)
    parser.add_argument("--expected-release-sha", required=True)
    parser.add_argument("--expected-release-repo", required=True)
    parser.add_argument("--expected-source-repo", required=True)
    parser.add_argument("--expected-source-sha", required=True)
    parser.add_argument("--expected-source-version", required=True)
    args = parser.parse_args()

    token = run_cmd(["gcloud", "auth", "print-access-token"])
    service_url = (
        "https://run.googleapis.com/v2/projects/"
        f"{args.project}/locations/{args.region}/services/{args.service}"
    )
    service = fetch_json(service_url, {"Authorization": f"Bearer {token}"})

    image_ref = service["template"]["containers"][0]["image"]
    if not image_ref_matches_expected_prefix(image_ref, args.expected_image_prefix):
        raise SystemExit(
            "image mismatch: expected prefix "
            f"'{args.expected_image_prefix}', got '{image_ref}'"
        )

    public_base = service["uri"].rstrip("/")
    health = fetch_json(f"{public_base}/health")
    status = fetch_json(f"{public_base}/status")

    assert_equal(health["service"], args.service, "health service")
    assert_equal(health["version"], args.expected_version, "health version")
    assert_equal(health["release_repo"], args.expected_release_repo, "health release_repo")
    assert_equal(health["overlay"], args.expected_overlay, "health overlay")
    assert_equal(health["release_sha"], args.expected_release_sha, "health release_sha")
    assert_equal(
        health["source_of_truth"]["repo"], args.expected_source_repo, "health source repo"
    )
    assert_equal(
        health["source_of_truth"]["sha"], args.expected_source_sha, "health source sha"
    )
    assert_equal(
        health["source_of_truth"]["version"],
        args.expected_source_version,
        "health source version",
    )

    assert_equal(status["service"], args.service, "status service")
    assert_equal(status["version"], args.expected_version, "status version")
    assert_equal(status["release_repo"], args.expected_release_repo, "status release_repo")
    assert_equal(status["overlay"], args.expected_overlay, "status overlay")
    assert_equal(status["release_sha"], args.expected_release_sha, "status release_sha")

    print(
        json.dumps(
            {
                "ok": True,
                "service": args.service,
                "uri": public_base,
                "image": image_ref,
                "release_sha": health["release_sha"],
                "overlay": health["overlay"],
                "source_of_truth": health["source_of_truth"],
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except urllib.error.HTTPError as exc:
        raise SystemExit(f"http error {exc.code}: {exc.reason}") from exc
