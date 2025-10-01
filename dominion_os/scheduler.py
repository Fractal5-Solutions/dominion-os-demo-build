from __future__ import annotations

from typing import List

from .process import Process


class Scheduler:
    """Lightweight cooperative scheduler for the Dominion demo."""

    def __init__(self) -> None:
        self._processes: List[Process] = []
        self.ticks: int = 0

    def add(self, process: Process) -> None:
        self._processes.append(process)

    def tick(self) -> None:
        survivors: List[Process] = []
        for process in self._processes:
            if process.step():
                survivors.append(process)
        self._processes = survivors
        self.ticks += 1

    @property
    def process_count(self) -> int:
        return len(self._processes)
