from __future__ import annotations

import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Dict

from .process import Process
from .scheduler import Scheduler


VERSION = "0.1.0"
_IMAGE_NAME = "dominion_os_image.json"


def _orchestrator(metrics: Dict[str, int]) -> Process:
    def generator():
        tick = 0
        backlog = 2
        while True:
            arrivals = (tick % 3) + 1
            backlog += arrivals
            processed = min(backlog, 3)
            backlog -= processed
            metrics["processed"] += processed
            metrics["arrivals"] += arrivals
            if backlog > 4:
                metrics["alerts"] += 1
            metrics["backlog"] = backlog
            tick += 1
            yield

    return Process(pid=1, name="demo-orchestrator", target=generator)


def demo_run(duration: int = 120) -> int:
    metrics: Dict[str, int] = {"processed": 0, "arrivals": 0, "alerts": 0, "backlog": 0}
    scheduler = Scheduler()
    scheduler.add(_orchestrator(metrics))

    timeline = []
    for tick in range(duration):
        scheduler.tick()
        timeline.append(
            {
                "tick": tick + 1,
                "processed": metrics["processed"],
                "arrivals": metrics["arrivals"],
                "backlog": metrics["backlog"],
                "alerts": metrics["alerts"],
            }
        )

    timestamp = datetime.now(UTC).isoformat()

    report = {
        "version": VERSION,
        "ticks": duration,
        "metrics": metrics,
        "timeline": timeline[:10],
        "generated_at": timestamp,
    }

    Path("run-report.json").write_text(json.dumps(report, indent=2))
    return duration


def build_image() -> Path:
    build_dir = Path("build")
    build_dir.mkdir(parents=True, exist_ok=True)
    image_path = build_dir / _IMAGE_NAME
    payload = {
        "version": VERSION,
        "created_at": datetime.now(UTC).isoformat(),
        "components": ["scheduler", "process", "cli"],
        "notes": "Demo image generated locally for Dominion OS showcase.",
    }
    image_path.write_text(json.dumps(payload, indent=2))
    return image_path
