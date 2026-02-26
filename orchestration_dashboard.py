from __future__ import annotations

import argparse
import json
import time
from datetime import UTC, datetime
from pathlib import Path
from typing import Any, Dict, List, Tuple

from command_core import _box, _cls


def _read_json(path: Path) -> Tuple[Dict[str, Any] | None, str | None]:
    try:
        return json.loads(path.read_text(encoding="utf-8")), None
    except FileNotFoundError:
        return None, "missing"
    except json.JSONDecodeError as e:
        return None, f"invalid_json: {e}"


def _latest_by_name(glob: str) -> Path | None:
    paths = sorted(Path(".").glob(glob))
    return paths[-1] if paths else None


def _tail_lines(path: Path, max_lines: int = 12, max_bytes: int = 64 * 1024) -> List[str]:
    try:
        data = path.read_bytes()
    except FileNotFoundError:
        return []

    if len(data) > max_bytes:
        data = data[-max_bytes:]
        cut = data.find(b"\n")
        if cut != -1:
            data = data[cut + 1 :]

    return data.decode("utf-8", errors="replace").splitlines()[-max_lines:]


def collect_status() -> Dict[str, Any]:
    now = datetime.now(tz=UTC).isoformat().replace("+00:00", "Z")

    session_path = Path("dist/command_core/session.json")
    session, session_err = _read_json(session_path)

    flight_path = _latest_by_name("dist/command_core/flight_*.json")
    flight, flight_err = _read_json(flight_path) if flight_path else (None, "missing")

    sovereign_cfg, sovereign_cfg_err = _read_json(Path("config/sovereign-config.json"))

    events_path = Path("dist/command_core/events.log")
    events_tail = _tail_lines(events_path, max_lines=12)

    return {
        "utc": now,
        "command_core": {
            "session_path": str(session_path),
            "session": session,
            "session_error": session_err,
            "latest_flight_path": str(flight_path) if flight_path else None,
            "latest_flight": flight,
            "latest_flight_error": flight_err,
            "events_path": str(events_path),
            "events_tail": events_tail,
        },
        "config": {
            "sovereign_config": sovereign_cfg,
            "sovereign_config_error": sovereign_cfg_err,
        },
    }


def _render(status: Dict[str, Any], width: int = 100) -> str:
    width = max(width, 60)
    header = f"Dominion Orchestration Dashboard — Local (UTC {status['utc']})"
    header = header[:width]

    session = status["command_core"]["session"] or {}
    cfg = status["config"]["sovereign_config"] or {}

    cc_lines = [
        f"Scale: {session.get('scale', 'n/a')}",
        f"Ticks: {session.get('ticks', 'n/a')}",
        f"Divisions: {session.get('divisions', 'n/a')}  Services: {session.get('services', 'n/a')}",
        f"Processed: {session.get('processed', 'n/a')}  Backlog: {session.get('backlog', 'n/a')}",
        f"Latest flight: {Path(status['command_core']['latest_flight_path'] or 'n/a').name}",
    ]

    cfg_lines = [
        f"Sovereign mode: {cfg.get('sovereign_mode', 'n/a')}",
        f"NHITL enabled: {cfg.get('nhitl_enabled', cfg.get('nhitl', 'n/a'))}",
    ]

    events_tail = status["command_core"]["events_tail"] or []
    if not events_tail:
        events_tail = ["(no events.log found)"]

    boxes = []
    boxes += _box(cc_lines, width, title="Command Core")
    boxes += [""]  # spacer
    boxes += _box(cfg_lines, width, title="Config")
    boxes += [""]  # spacer
    boxes += _box(events_tail, width, title="Recent Events (tail)")

    return "\n".join([header, ""] + boxes)


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Dominion OS orchestration dashboard (local)")
    parser.add_argument("--json", action="store_true", help="Print status as JSON and exit")
    parser.add_argument(
        "--watch",
        type=int,
        default=0,
        metavar="SECONDS",
        help="Refresh every N seconds until Ctrl+C",
    )
    args = parser.parse_args(argv)

    if args.json:
        print(json.dumps(collect_status(), indent=2))
        return 0

    try:
        while True:
            status = collect_status()
            _cls()
            print(_render(status), flush=True)
            if not args.watch:
                return 0
            time.sleep(max(1, args.watch))
    except KeyboardInterrupt:
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
