from __future__ import annotations

import json
import os
import time
from dataclasses import dataclass
from functools import partial
from pathlib import Path


def _seeded_rand(seed: int) -> int:
    # Simple LCG for deterministic pseudo-randomness (no external deps)
    # Returns 0..2^31-1
    a = 1103515245
    c = 12345
    m = 2**31
    return (a * seed + c) % m


@dataclass
class Event:
    tick: int
    entity: str
    action: str
    message: str


@dataclass
class Service:
    name: str
    backlog: int = 0
    processed: int = 0
    seed: int = 1

    def generator(self, events: list[Event], qual_name: str):
        tick = 0
        seed = self.seed
        while True:
            # Deterministic arrivals based on seed and tick
            seed = _seeded_rand(seed + tick)
            arrivals = seed % 4  # 0..3 new tasks
            if arrivals:
                self.backlog += arrivals
                message = f"+{arrivals} => {self.backlog}"
                events.append(Event(tick, qual_name, "arrivals", message))

            # Process up to 2 per step
            capacity = 2 if (tick % 3) else 3
            done = min(capacity, self.backlog)
            if done:
                self.backlog -= done
                self.processed += done
                message = f"-{done} => {self.backlog}"
                events.append(Event(tick, qual_name, "processed", message))
            else:
                events.append(Event(tick, qual_name, "idle", "no work"))

            tick += 1
            yield


@dataclass
class Division:
    name: str
    services: list[Service]


@dataclass
class Enterprise:
    name: str
    divisions: list[Division]


def build_enterprise(scale: str = "small") -> Enterprise:
    if scale == "large":
        divs, svcs = 8, 12
    elif scale == "medium":
        divs, svcs = 4, 8
    else:
        divs, svcs = 3, 5
    divisions = []
    for d in range(divs):
        services = [
            Service(name=f"svc-{d+1}-{i+1}", seed=(d + 1) * (i + 3))
            for i in range(svcs)
        ]
        divisions.append(Division(name=f"div-{d+1}", services=services))
    return Enterprise(name="Dominion Enterprises", divisions=divisions)


# Minimal UI primitives (portable to Windows without curses)
def _cls() -> None:
    if os.name == "nt":
        os.system("cls")
    else:
        print("\x1b[2J\x1b[H", end="")  # ANSI clear


def _box(lines: list[str], w: int, title: str | None = None) -> list[str]:
    w = max(w, 10)
    out = []
    top = "+" + ("-" * (w - 2)) + "+"
    out.append(top)
    if title:
        t = (" " + title + " ")[: w - 2]
        out.append("|" + t.ljust(w - 2) + "|")
        out.append("|" + ("-" * (w - 2)) + "|")
    for ln in lines:
        out.append("|" + ln[: w - 2].ljust(w - 2) + "|")
    out.append(top)
    return out


def _render_dashboard(
    tick: int,
    ent: Enterprise,
    events: list[Event],
    width: int = 100,
    height: int = 32,
) -> str:
    # Left: enterprise tree; Right: recent events; Bottom: KPIs
    # Build tree
    left: list[str] = [f"Enterprise: {ent.name}"]
    for div in ent.divisions[:10]:
        left.append(f"- {div.name}")
        for svc in div.services[:12]:
            summary = f"  · {svc.name}  Q:{svc.backlog}  ✔:{svc.processed}"
            left.append(summary)
    left_box = _box(
        left[: height - 10],
        width // 2,
        title="Command Core — Topology",
    )

    # Events window
    recent = events[-(height - 10) :]
    right_lines = [f"t={e.tick:04d} {e.entity} {e.action}: {e.message}" for e in recent]
    right_box = _box(
        right_lines,
        width - (width // 2),
        title="Event Stream",
    )

    # KPIs bottom
    total_backlog = sum(s.backlog for d in ent.divisions for s in d.services)
    total_processed = sum(s.processed for d in ent.divisions for s in d.services)
    services_total = sum(len(d.services) for d in ent.divisions)
    divisions_total = len(ent.divisions)
    kpi = [
        f"Tick: {tick}",
        f"Services: {services_total}  Divisions: {divisions_total}",
        f"Backlog: {total_backlog}  Processed: {total_processed}",
    ]
    bottom = _box(kpi, width, title="Operational KPIs")

    # Merge left and right side-by-side
    max_side = max(len(left_box), len(right_box))
    left_box += [" "] * (max_side - len(left_box))
    right_box += [" "] * (max_side - len(right_box))
    rows = [
        f"{left_line} {right_line}"
        for left_line, right_line in zip(left_box, right_box)
    ]
    rows += bottom
    header = [f"Dominion Command Core — Enterprise Orchestration (t={tick})"]
    return "\n" + "\n".join(header + rows)


def run_command_core(
    duration_ticks: int = 120,
    scale: str = "small",
    refresh_ms: int = 0,
    ui: bool = True,
    outdir: Path | None = None,
) -> dict[str, int | str]:
    """Run the Command Core demo.

    - duration_ticks: how many scheduler cycles to run
    - scale: small|medium|large (number of divisions/services)
    - refresh_ms: pause between frames when ui=True
    - ui: when False, runs headless and only collects artifacts
    - outdir: where to write artifacts (events.log, session.json, summary.txt)
    """
    from dominion_os.process import Process
    from dominion_os.scheduler import Scheduler

    ent = build_enterprise(scale)
    events: list[Event] = []
    sched = Scheduler()

    # Attach a process per service
    for d in ent.divisions:
        for s in d.services:
            qual = f"{d.name}/{s.name}"
            generator_target = partial(s.generator, events, qual)
            proc = Process(
                pid=hash(qual) & 0xFFFF,
                name=qual,
                target=generator_target,
            )
            sched.add(proc)

    # Output directory
    outdir = outdir or (Path("dist") / "command_core")
    outdir.mkdir(parents=True, exist_ok=True)
    events_path = outdir / "events.log"
    session_path = outdir / "session.json"
    summary_path = outdir / "summary.txt"

    # Main loop
    for t in range(duration_ticks):
        sched.tick()
        if ui:
            _cls()
            frame = _render_dashboard(t, ent, events)
            print(frame)
            if refresh_ms:
                time.sleep(refresh_ms / 1000)

    # Artifacts
    with events_path.open("w", encoding="utf-8") as f:
        for e in events:
            f.write(f"{e.tick}\t{e.entity}\t{e.action}\t{e.message}\n")

    services_count = sum(len(d.services) for d in ent.divisions)
    processed_total = sum(s.processed for d in ent.divisions for s in d.services)
    backlog_total = sum(s.backlog for d in ent.divisions for s in d.services)

    session: dict[str, int | str] = {
        "scale": scale,
        "ticks": duration_ticks,
        "divisions": len(ent.divisions),
        "services": services_count,
        "processed": processed_total,
        "backlog": backlog_total,
    }
    session_path.write_text(json.dumps(session, indent=2), encoding="utf-8")

    summary_lines = [
        "Dominion Command Core Session",
        f"Ticks: {session['ticks']}",
        f"Scale: {session['scale']}",
        f"Divisions: {session['divisions']}",
        f"Services: {session['services']}",
        f"Processed: {session['processed']}",
        f"Backlog: {session['backlog']}",
        f"Events: {len(events)}",
    ]
    summary_path.write_text("\n".join(summary_lines), encoding="utf-8")
    return session
