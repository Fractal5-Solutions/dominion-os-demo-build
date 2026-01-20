from __future__ import annotations

import json
import os
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict


@dataclass
class Span:
    name: str
    start: float
    end: float | None = None
    attrs: Dict[str, Any] | None = None

    def finish(self) -> None:
        self.end = time.time()

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "start": self.start,
            "end": self.end,
            "duration_ms": None if self.end is None else (self.end - self.start) * 1000.0,
            "attrs": self.attrs or {},
        }


class Tracer:
    def __init__(self, out_path: Path | str = Path("telemetry") / "traces.jsonl") -> None:
        self.out_path = Path(out_path)
        self.out_path.parent.mkdir(parents=True, exist_ok=True)

    def span(self, name: str, **attrs: Any) -> Span:
        return Span(name=name, start=time.time(), attrs=attrs or {})

    def emit(self, span: Span) -> None:
        rec = span.to_dict()
        with self.out_path.open("a", encoding="utf-8") as f:
            f.write(json.dumps(rec) + "\n")


def get_tracer() -> Tracer:
    out = os.getenv("DOMINION_TRACES_PATH", str(Path("telemetry") / "traces.jsonl"))
    return Tracer(out)
