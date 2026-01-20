from __future__ import annotations

from dataclasses import dataclass, field
from typing import List

from .process import Process


@dataclass
class Scheduler:
    queue: List[Process] = field(default_factory=list)

    def add(self, p: Process) -> None:
        self.queue.append(p)

    def tick(self) -> bool:
        active = False
        next_queue: List[Process] = []
        for p in self.queue:
            if p.step():
                active = True
                next_queue.append(p)
        self.queue = next_queue
        return active
