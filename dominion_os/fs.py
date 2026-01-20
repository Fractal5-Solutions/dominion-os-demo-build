from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict


@dataclass
class InMemoryFS:
    files: Dict[str, str] = field(default_factory=dict)

    def write(self, path: str, content: str) -> None:
        self.files[path] = content

    def read(self, path: str) -> str:
        return self.files[path]

    def snapshot(self) -> Dict[str, str]:
        return dict(self.files)
