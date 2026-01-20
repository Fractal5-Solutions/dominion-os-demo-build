__all__ = [
    "Kernel",
    "Process",
    "InMemoryFS",
    "install_model",
]

import re
from pathlib import Path
from typing import Optional

from .fs import InMemoryFS
from .kernel import Kernel
from .net_installer import install_model
from .process import Process

try:  # Prefer installed distribution metadata
    from importlib.metadata import version as _pkg_version

    _dist_version: Optional[str] = _pkg_version("dominion-os")
except ModuleNotFoundError:  # pragma: no cover - distribution not installed
    _dist_version = None

# Attempt to read pyproject version (source tree precedence)
_file_version: Optional[str] = None
_pyproject_path = Path(__file__).resolve().parent.parent / "pyproject.toml"
if _pyproject_path.exists():  # pragma: no cover - simple file read
    try:
        _text = _pyproject_path.read_text(encoding="utf-8")
        m = re.search(r'^version\s*=\s*"([^"]+)"', _text, re.MULTILINE)
        if m:
            _file_version = m.group(1)
    except OSError:  # pragma: no cover - unreadable file
        _file_version = None

# Version resolution order:
# 1. pyproject (source tree) > 2. dist metadata > 3. neutral fallback
if _file_version:
    __version__ = _file_version
elif _dist_version:
    __version__ = _dist_version
else:  # pragma: no cover - last resort fallback; neutral to avoid manual sync
    __version__ = "0.0.0"
