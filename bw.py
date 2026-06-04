import json
from pathlib import Path
from flask import jsonify, make_response, request
from command_core import BASE_DIR, app, now_iso

P = Path(BASE_DIR) / "public_feeds" / "bluewave-ai-live.json"
S = "bluewave.public.live.v1"
O = {"https://www.bluewaveactiongroup.ca", "https://bluewaveactiongroup.ca"}


def rsp(data, code=200):
    r = make_response(jsonify(data), code)
    origin = request.headers.get("Origin")
    if origin in O:
        r.headers["Access-Control-Allow-Origin"] = origin
        r.headers["Vary"] = "Origin"
        r.headers["Access-Control-Allow-Methods"] = "GET, OPTIONS"
        r.headers["Access-Control-Allow-Headers"] = "Content-Type"
    return r


def fb():
    return {"schemaVersion": S, "generatedAt": now_iso(), "status": "degraded", "entitySlug": "blue-wave-action-group-inc", "page": "blue-wave-ai", "summary": {"title": "BlueWave AI Signal", "body": "The feed is not available right now.", "updatedLabel": "Unavailable"}, "sections": [], "proof": []}


@app.route("/api/public/bluewave-ai/live", methods=["GET", "OPTIONS"])
def bw_live():
    if request.method == "OPTIONS":
        return rsp({}, 204)
    try:
        data = json.loads(P.read_text(encoding="utf-8"))
    except Exception:
        return rsp(fb())
    if not isinstance(data, dict) or data.get("schemaVersion") != S:
        return rsp(fb())
    return rsp(data)
