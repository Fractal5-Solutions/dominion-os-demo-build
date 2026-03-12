from __future__ import annotations

import os
from datetime import datetime, timezone
from http import HTTPStatus

from flask import Flask, jsonify, send_file

app = Flask(__name__)


def utcnow_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


@app.route("/")
def serve_widget():
    return send_file("widget.html", mimetype="text/html")


@app.route("/health")
@app.route("/ready")
def health():
    return (
        jsonify(
            {
                "status": "healthy",
                "service": "askphi-widget",
                "timestamp": utcnow_iso(),
            }
        ),
        HTTPStatus.OK,
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
