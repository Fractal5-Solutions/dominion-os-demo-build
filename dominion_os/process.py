from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Generator, Optional

ProcessTarget = Callable[[], Generator[None, None, None]]


@dataclass
class Process:
    pid: int
    name: str
    target: ProcessTarget
    state: str = "ready"
    ticks: int = 0
    _gen: Optional[Generator[None, None, None]] = None

    def step(self) -> bool:
        if self._gen is None:
            self._gen = self.target()
            self.state = "running"
        try:
            next(self._gen)
            self.ticks += 1
            return True
        except StopIteration:
            self.state = "done"
            return False


def countdown(n: int) -> Generator[None, None, None]:
    while n > 0:
        n -= 1
        yield


def writer(
    write_fn: Callable[[str, str], None],
    path: str,
    prefix: str,
    repeats: int = 3,
) -> Generator[None, None, None]:
    for i in range(repeats):
        write_fn(path, f"{prefix}-{i}")
        yield
