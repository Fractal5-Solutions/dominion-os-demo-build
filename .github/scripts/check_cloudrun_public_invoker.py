#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


def resolve_gcloud(explicit: str | None) -> str:
    candidates: list[str] = []
    if explicit:
        candidates.append(explicit)
    env_bin = os.environ.get("GCLOUD_BIN")
    if env_bin:
        candidates.append(env_bin)
    candidates.extend(["gcloud", "gcloud.cmd", "gcloud.exe"])

    local_appdata = os.environ.get("LOCALAPPDATA")
    if local_appdata:
        candidates.append(
            str(
                Path(local_appdata)
                / "Google"
                / "Cloud SDK"
                / "google-cloud-sdk"
                / "bin"
                / "gcloud.cmd"
            )
        )

    for candidate in candidates:
        if not candidate:
            continue
        if Path(candidate).exists():
            return candidate
        resolved = shutil.which(candidate)
        if resolved:
            return resolved

    sys.stderr.write(
        "Unable to locate gcloud binary. Set --gcloud-bin or GCLOUD_BIN.\n"
    )
    sys.exit(2)


def run_json(cmd: list[str]) -> list[dict]:
    proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if proc.returncode != 0:
        sys.stderr.write(f"Command failed ({proc.returncode}): {' '.join(cmd)}\n")
        if proc.stderr:
            sys.stderr.write(proc.stderr)
        sys.exit(proc.returncode)
    try:
        payload = json.loads(proc.stdout or "[]")
    except json.JSONDecodeError as exc:
        sys.stderr.write(f"Invalid JSON from command: {' '.join(cmd)}\n")
        sys.stderr.write(str(exc) + "\n")
        sys.exit(2)
    if isinstance(payload, list):
        return payload
    return [payload]


def load_allowlist(path: Path) -> set[str]:
    if not path.exists():
        return set()
    items: set[str] = set()
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        items.add(line)
    return items


def parse_csv_services(value: str | None) -> set[str]:
    if not value:
        return set()
    return {item.strip() for item in value.split(",") if item.strip()}


def has_public_invoker(policy: dict) -> bool:
    for binding in policy.get("bindings", []):
        if binding.get("role") != "roles/run.invoker":
            continue
        members = binding.get("members", [])
        if "allUsers" in members:
            return True
    return False


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Fail if Cloud Run services expose allUsers invoker outside allowlist."
    )
    parser.add_argument("--project", required=True, help="GCP project id")
    parser.add_argument(
        "--region",
        action="append",
        dest="regions",
        help="Cloud Run region; can be specified multiple times",
    )
    parser.add_argument(
        "--allowlist-file",
        default=".github/cloudrun-public-allowlist.txt",
        help="Path to newline-delimited list of services allowed to be public",
    )
    parser.add_argument(
        "--allow-public-services",
        default="",
        help="Optional comma-delimited services allowed to be public",
    )
    parser.add_argument(
        "--gcloud-bin",
        default="",
        help="Optional gcloud executable path (or use GCLOUD_BIN env var)",
    )
    args = parser.parse_args()
    gcloud_bin = resolve_gcloud(args.gcloud_bin)

    regions = args.regions or ["us-central1"]
    allowlist = load_allowlist(Path(args.allowlist_file))
    allowlist |= parse_csv_services(args.allow_public_services)
    allowlist |= parse_csv_services(os.environ.get("ALLOW_PUBLIC_SERVICES"))

    violations: list[dict[str, str]] = []
    allowed_public: list[dict[str, str]] = []

    for region in regions:
        services = run_json(
            [
                gcloud_bin,
                "run",
                "services",
                "list",
                "--project",
                args.project,
                "--region",
                region,
                "--platform",
                "managed",
                "--format=json",
            ]
        )
        for service in services:
            name = service.get("metadata", {}).get("name")
            if not name:
                continue
            policy = run_json(
                [
                    gcloud_bin,
                    "run",
                    "services",
                    "get-iam-policy",
                    name,
                    "--project",
                    args.project,
                    "--region",
                    region,
                    "--format=json",
                ]
            )[0]
            is_public = has_public_invoker(policy)
            if not is_public:
                continue
            row = {"service": name, "region": region}
            if name in allowlist:
                allowed_public.append(row)
            else:
                violations.append(row)

    report = {
        "project": args.project,
        "regions": regions,
        "allowlist_count": len(allowlist),
        "allowed_public": allowed_public,
        "violations": violations,
    }
    print(json.dumps(report, indent=2))

    if violations:
        for row in violations:
            print(
                f"::error title=Public Invoker Drift::{row['service']} in {row['region']} has allUsers run.invoker"
            )
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
