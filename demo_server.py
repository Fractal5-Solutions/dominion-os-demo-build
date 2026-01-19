from __future__ import annotations

import functools
import json
import os
import subprocess
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


def _truthy(value: str | None) -> bool:
    return (value or "").strip().lower() in {"1", "true", "yes", "y", "on"}


def _maybe_generate(dist_dir: Path) -> None:
    if not _truthy(os.getenv("GENERATE_ON_START", "true")):
        return

    scale = os.getenv("DEMO_SCALE", "small")
    duration = os.getenv("DEMO_DURATION", "120")

    cmd = [
        "python",
        "demo_build.py",
        "flagship",
        "--no-ui",
        "--scale",
        scale,
        "--duration",
        duration,
    ]
    subprocess.run(cmd, check=True)
    (dist_dir / "server_status.json").write_text(
        json.dumps(
            {
                "generated": True,
                "scale": scale,
                "duration": int(duration),
            },
            indent=2,
        ),
        encoding="utf-8",
    )


class Handler(SimpleHTTPRequestHandler):
    def do_GET(self) -> None:  # noqa: N802
        if self.path in {"/health", "/healthz"}:
            payload = {"ok": True}
            body = json.dumps(payload).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        super().do_GET()


def main() -> None:
    dist_dir = Path(os.getenv("DIST_DIR", "dist")).resolve()
    dist_dir.mkdir(parents=True, exist_ok=True)
    _maybe_generate(dist_dir)

    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8080"))

    handler = functools.partial(Handler, directory=str(dist_dir))
    httpd = ThreadingHTTPServer((host, port), handler)
    httpd.serve_forever()


if __name__ == "__main__":
    main()
