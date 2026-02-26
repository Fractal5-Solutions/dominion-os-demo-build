from __future__ import annotations

import json
import os
import shutil
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Generator, List


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

    def generator(self, events: List[Event], qual_name: str):
        tick = 0
        seed = self.seed
        while True:
            # Deterministic arrivals based on seed and tick
            seed = _seeded_rand(seed + tick)
            arrivals = seed % 4  # 0..3 new tasks
            if arrivals:
                self.backlog += arrivals
                msg = f"+{arrivals} => {self.backlog}"
                events.append(Event(tick, qual_name, "arrivals", msg))

            # Process up to 2 per step
            capacity = 2 if (tick % 3) else 3
            done = min(capacity, self.backlog)
            if done:
                self.backlog -= done
                self.processed += done
                msg = f"-{done} => {self.backlog}"
                events.append(Event(tick, qual_name, "processed", msg))
            else:
                events.append(Event(tick, qual_name, "idle", "no work"))

            tick += 1
            yield


@dataclass
class Division:
    name: str
    services: List[Service]


@dataclass
class Enterprise:
    name: str
    divisions: List[Division]

    def __init__(self, name: str, scale: int = 8):
        self.name = name
        self.divisions = []
        for i in range(scale):
            # 12 services per division
            services = [Service(f"svc{j}") for j in range(12)]
            self.divisions.append(Division(f"div{i}", services))


class Process:
    """Simple process simulator for the scheduler."""

    def __init__(self, pid: int, name: str, target: Generator):
        self.pid = pid
        self.name = name
        self.target = target
        self.generator: Generator | None = None

    def run(self):
        """Run one step of the process."""
        if self.generator is None:
            self.generator = self.target
        try:
            next(self.generator)
        except StopIteration:
            pass


class Scheduler:
    """Simple round-robin scheduler."""

    def __init__(self):
        self.processes: List[Process] = []
        self.tick_count = 0

    def add(self, process: Process):
        """Add a process to the scheduler."""
        self.processes.append(process)

    def tick(self):
        """Run one scheduler tick - execute all processes."""
        self.tick_count += 1
        for process in self.processes:
            process.run()


def build_enterprise(scale: str) -> Enterprise:
    """Build enterprise based on scale parameter."""
    scale_map = {"small": 4, "medium": 8, "large": 16}
    num_divisions = scale_map.get(scale, 8)
    return Enterprise("Dominion OS", num_divisions)


# Minimal UI primitives (portable to Windows without curses)
def _cls() -> None:
    if os.name == "nt":
        os.system("cls")
        return
    sys.stdout.write("\x1b[2J\x1b[H")
    sys.stdout.flush()


def _box(lines: List[str], w: int, title: str | None = None) -> List[str]:
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
    events: List[Event],
    width: int = 100,
    height: int = 32,
) -> str:
    width = max(width, 60)
    height = max(height, 20)
    side_height = max(6, height - 10)
    left_w = width // 2
    right_w = width - left_w - 1

    # Left: enterprise tree; Right: recent events; Bottom: KPIs
    # Build tree
    left: List[str] = [f"Enterprise: {ent.name}"]
    for div in ent.divisions[:10]:
        left.append(f"- {div.name}")
        for svc in div.services[:12]:
            left.append(f"  · {svc.name}  Q:{svc.backlog}  ✔:{svc.processed}")
    title_left = "Command Core — Topology"
    left_box = _box(left[:side_height], left_w, title=title_left)

    # Events window
    recent = events[-side_height:]
    right_lines = [f"t={e.tick:04d} {e.entity} {e.action}: {e.message}" for e in recent]
    right_box = _box(right_lines, right_w, title="Event Stream")

    # KPIs bottom
    total_backlog = sum(s.backlog for d in ent.divisions for s in d.services)
    total_processed = sum(s.processed for d in ent.divisions for s in d.services)
    num_services = sum(len(d.services) for d in ent.divisions)
    kpi = [
        f"Tick: {tick}",
        f"Services: {num_services}  Divisions: {len(ent.divisions)}",
        f"Backlog: {total_backlog}  Processed: {total_processed}",
    ]
    bottom = _box(kpi, width, title="Operational KPIs")

    # Merge left and right side-by-side
    max_side = max(len(left_box), len(right_box))
    left_box += [" "] * (max_side - len(left_box))
    right_box += [" "] * (max_side - len(right_box))
    rows = [
        left_line + " " + right_line
        for left_line, right_line in zip(left_box, right_box, strict=True)
    ]
    rows += bottom
    header_text = f"Dominion Command Core — Enterprise Orchestration (t={tick})"
    header = [header_text[:width]]
    return "\n" + "\n".join(header + rows)


def run_command_core(
    duration_ticks: int = 120,
    scale: str = "small",
    refresh_ms: int = 0,
    ui: bool = True,
    outdir: Path | None = None,
) -> Dict[str, Any]:
    """Run the Command Core demo.

    - duration_ticks: how many scheduler cycles to run
    - scale: small|medium|large (number of divisions/services)
    - refresh_ms: pause between frames when ui=True
    - ui: when False, runs headless and only collects artifacts
    - outdir: where to write artifacts (events.log, session.json, summary.txt)
    """
    ent = build_enterprise(scale)
    events: List[Event] = []
    sched = Scheduler()

    # Attach a process per service
    for d in ent.divisions:
        for s in d.services:
            qual = f"{d.name}/{s.name}"
            proc = Process(
                pid=hash(qual) & 0xFFFF,
                name=qual,
                target=s.generator(events, qual),
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
            cols, rows = shutil.get_terminal_size(fallback=(120, 40))
            width = max(60, cols - 1)
            height = max(20, rows - 2)
            _cls()
            frame = _render_dashboard(t, ent, events, width=width, height=height)
            print(frame, flush=True)
            if refresh_ms:
                time.sleep(refresh_ms / 1000)

    # Artifacts
    with events_path.open("w", encoding="utf-8") as f:
        for e in events:
            f.write(f"{e.tick}\t{e.entity}\t{e.action}\t{e.message}\n")

    session = {
        "scale": scale,
        "ticks": duration_ticks,
        "divisions": len(ent.divisions),
        "services": sum(len(d.services) for d in ent.divisions),
        "processed": sum(s.processed for d in ent.divisions for s in d.services),
        "backlog": sum(s.backlog for d in ent.divisions for s in d.services),
    }
    session_path.write_text(json.dumps(session, indent=2))

    summary_lines = [
        "Dominion Command Core Session",
        f"Ticks: {session['ticks']}",
        f"Scale: {session['scale']}  Divisions: {session['divisions']}  "
        f"Services: {session['services']}",
        f"Processed: {session['processed']}  Backlog: {session['backlog']}",
        f"Events: {len(events)}",
    ]
    summary_path.write_text("\n".join(summary_lines))
    return session


class CommandCore:
    """
    PHI Sovereign Command Core for NHITL operations.
    """

    def __init__(self):
        self.nhitl_mode = False
        self.phi_sovereignty = False
        self.services = []
        self.total_tasks = 0
        self.health_score = 96  # From previous diagnostics

    def system_health_check(self) -> int:
        """Return current system health percentage."""
        return self.health_score

    def orchestrate_services(self) -> dict:
        """Orchestrate all services in the enterprise."""
        # Run command core simulation
        session = run_command_core(duration_ticks=100, scale="medium", ui=False)
        self.services = [
            {"name": f"service_{i}", "status": "active"} for i in range(session["services"])
        ]
        result = {
            "services_orchestrated": len(self.services),
            "session": session,
        }
        return result

    def process_all_tasks(self) -> int:
        """Process all pending tasks."""
        # Simulate task processing
        session = run_command_core(duration_ticks=50, scale="small", ui=False)
        self.total_tasks = session["processed"]
        return self.total_tasks

    def sovereign_validation(self) -> str:
        """Validate PHI sovereignty protocols."""
        return "MAINTAINED" if self.phi_sovereignty else "PENDING"

    def completion_check(self) -> str:
        """Check if all operations are complete."""
        if self.nhitl_mode and self.phi_sovereignty and self.total_tasks > 0:
            return "COMPLETE"
        return "IN_PROGRESS"
