from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable

from .process import Process
from .scheduler import Scheduler


@dataclass
class Kernel:
    scheduler: Scheduler

    def add_processes(self, processes: Iterable[Process]) -> None:
        for p in processes:
            self.scheduler.add(p)

    def run_until_idle(self, max_ticks: int | None = None) -> int:
        ticks = 0
        while True:
            active = self.scheduler.tick()
            ticks += 1
            if not active:
                break
            if max_ticks is not None and ticks >= max_ticks:
                break
        return ticks
