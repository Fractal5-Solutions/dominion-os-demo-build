from __future__ import annotations

from dataclasses import dataclass, field
from typing import Callable, Generator, Optional

Coroutine = Generator[None, None, None]


@dataclass
class Process:
    """Cooperative process wrapper used by the demo scheduler."""

    pid: int
    name: str
    target: Callable[[], Coroutine]
    _coroutine: Optional[Coroutine] = field(init=False, default=None)
    _alive: bool = field(init=False, default=True)

    def _ensure_coroutine(self) -> Coroutine:
        if self._coroutine is None:
            candidate = self.target()
            if not hasattr(candidate, "__next__"):
                raise TypeError("process target must return a generator")
            self._coroutine = candidate
        return self._coroutine

    @property
    def alive(self) -> bool:
        return self._alive

    def step(self) -> bool:
        if not self._alive:
            return False
        coro = self._ensure_coroutine()
        try:
            next(coro)
        except StopIteration:
            self._alive = False
        return self._alive
