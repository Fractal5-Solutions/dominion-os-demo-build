#!/usr/bin/env python3
"""High-signal repository secret scanner used by CI and pre-commit.

The scanner fails on concrete credential formats and credential-like assignment
values. It deliberately does not fail merely because documentation or source
code mentions words such as ``password``, ``token``, or ``secret``.
"""
from __future__ import annotations

import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parent.parent

SKIP_DIRS = {
    ".git",
    ".mypy_cache",
    ".pytest_cache",
    ".ruff_cache",
    ".venv",
    "__pycache__",
    "node_modules",
    "venv",
}

SKIP_SUFFIXES = {
    ".7z",
    ".avi",
    ".bmp",
    ".class",
    ".dll",
    ".docx",
    ".exe",
    ".gif",
    ".gz",
    ".ico",
    ".jar",
    ".jpeg",
    ".jpg",
    ".mov",
    ".mp3",
    ".mp4",
    ".pdf",
    ".png",
    ".pptx",
    ".pyc",
    ".so",
    ".tar",
    ".webp",
    ".whl",
    ".xlsx",
    ".zip",
}

MAX_TEXT_BYTES = 5 * 1024 * 1024

TOKEN_PATTERNS = {
    "GitHub token": re.compile(
        r"\b(?:gh[pousr]_[0-9A-Za-z_]{20,255}|github_pat_[0-9A-Za-z_]{20,255})\b"
    ),
    "OpenAI API key": re.compile(
        r"\bsk-(?:(?:proj|svcacct)-)?[0-9A-Za-z_-]{20,255}\b"
    ),
    "Stripe secret": re.compile(r"\bsk_(?:live|test)_[0-9A-Za-z_-]{16,255}\b"),
    "Stripe webhook secret": re.compile(r"\bwhsec_[0-9A-Za-z]{16,255}\b"),
    "Google API key": re.compile(r"\bAIza[0-9A-Za-z_-]{35}\b"),
    "AWS access key": re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    "Slack token": re.compile(r"\bxox[baprs]-[0-9A-Za-z-]{16,255}\b"),
    "Private key header": re.compile(r"-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----"),
}

SECRET_KEY_SUFFIX = r"(?:" + "|".join(
    [
        r"API[_-]?KEY",
        r"APIKEY",
        r"CLIENT[_-]?SECRET",
        r"SECRET[_-]?KEY",
        r"OAUTH[_-]?CLIENT[_-]?SECRET",
        r"JWT[_-]?SECRET(?:[_-]?KEY)?",
        r"GITHUB[_-]?TOKEN",
        r"ACCESS[_-]?TOKEN",
        r"REFRESH[_-]?TOKEN",
        r"WEBHOOK[_-]?SECRET",
        r"PRIVATE[_-]?KEY",
        r"PASSWORD",
        r"PASSPHRASE",
    ]
) + r")"

ASSIGNMENT_PATTERN = re.compile(
    rf"""
    ^\s*
    (?:export\s+)?
    [\"']?
    (?P<key>[A-Z0-9_.-]*{SECRET_KEY_SUFFIX})
    [\"']?
    \s*(?:=|:)\s*
    (?P<value>.*?)
    \s*[,;]?\s*$
    """,
    re.IGNORECASE | re.VERBOSE,
)

PLACEHOLDER_MARKERS = {
    "<newpass>",
    "<password>",
    "<secret>",
    "<token>",
    "change-me",
    "change_me",
    "change_this",
    "changeme",
    "dummy",
    "example",
    "fake",
    "insert_here",
    "not_set",
    "placeholder",
    "redacted",
    "replace-me",
    "replace_me",
    "sample",
    "token_here",
    "unset",
    "your_",
    "your-",
    "your ",
}

REFERENCE_PATTERNS = (
    re.compile(r"^\$\{[^}]+\}$"),
    re.compile(r"^\$[A-Za-z_][A-Za-z0-9_]*$"),
    re.compile(r"^%[A-Za-z_][A-Za-z0-9_]*%$"),
    re.compile(r"^\$\{\{.*\}\}$"),
    re.compile(r"^(?:secrets|env|vars)\.[A-Za-z0-9_.-]+$", re.IGNORECASE),
    re.compile(r"^(?:os\.getenv|process\.env)\b", re.IGNORECASE),
    re.compile(r"^[A-Za-z0-9_.-]+:latest$", re.IGNORECASE),
    re.compile(r"^(?:/)?secrets?/", re.IGNORECASE),
)


@dataclass(frozen=True)
class Finding:
    kind: str
    line_number: int
    raw: str
    context: str


def is_binary_string(data: bytes) -> bool:
    """Return True for data that is probably binary rather than UTF-8 text."""
    if b"\x00" in data:
        return True
    text = data.decode("utf-8", errors="ignore")
    non_printable = sum(
        1 for character in text if ord(character) < 9 or 13 < ord(character) < 32
    )
    return (non_printable / max(1, len(text))) > 0.3


def _strip_assignment_value(raw_value: str) -> str:
    value = raw_value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        value = value[1:-1].strip()
    elif " #" in value:
        value = value.split(" #", 1)[0].rstrip()
    return value


def _looks_like_placeholder_or_reference(value: str) -> bool:
    normalized = value.strip().lower()
    if not normalized:
        return True
    if normalized in {"none", "null", "nil", "false", "true", "***", "..."}:
        return True
    if normalized.startswith("<") or normalized.endswith(">"):
        return True
    if any(marker in normalized for marker in PLACEHOLDER_MARKERS):
        return True
    if re.fullmatch(r"[xX*_-]{6,}", value):
        return True
    return any(pattern.search(value) for pattern in REFERENCE_PATTERNS)


def _looks_like_credential_value(value: str) -> bool:
    if _looks_like_placeholder_or_reference(value):
        return False
    if len(value) < 6:
        return False
    if any(character.isspace() for character in value):
        # Quoted passphrases are retained by _strip_assignment_value, but prose
        # and shell command fragments should not become generic findings.
        return False
    return True


def _mask(value: str) -> str:
    if len(value) <= 8:
        return "<redacted>"
    return f"{value[:4]}...{value[-4:]}"


def _redacted_context(line: str, raw: str) -> str:
    compact = line.strip().replace("\t", " ")
    if raw:
        compact = compact.replace(raw, _mask(raw))
    return compact[:240]


def _line_number(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def scan_text(text: str) -> list[Finding]:
    findings: list[Finding] = []

    for kind, pattern in TOKEN_PATTERNS.items():
        for match in pattern.finditer(text):
            raw = match.group(0)
            if _looks_like_placeholder_or_reference(raw):
                continue
            line_number = _line_number(text, match.start())
            line = text.splitlines()[line_number - 1] if text.splitlines() else ""
            findings.append(
                Finding(kind, line_number, raw, _redacted_context(line, raw))
            )

    for line_number, line in enumerate(text.splitlines(), start=1):
        if not line.strip() or line.lstrip().startswith(("#", "//", "*")):
            continue
        match = ASSIGNMENT_PATTERN.match(line)
        if not match:
            continue
        value = _strip_assignment_value(match.group("value"))
        if not _looks_like_credential_value(value):
            continue
        findings.append(
            Finding(
                f"Credential assignment ({match.group('key')})",
                line_number,
                value,
                _redacted_context(line, value),
            )
        )

    # A single value can be detected both by a concrete token format and by its
    # assignment. Preserve the higher-confidence format finding only.
    unique: dict[tuple[int, str], Finding] = {}
    for finding in findings:
        key = (finding.line_number, finding.raw)
        current = unique.get(key)
        if current is None or current.kind.startswith("Credential assignment"):
            unique[key] = finding
    return sorted(unique.values(), key=lambda item: (item.line_number, item.kind))


def scan_file(path: os.PathLike[str] | str) -> list[Finding]:
    file_path = Path(path)
    try:
        if file_path.stat().st_size > MAX_TEXT_BYTES:
            return []
        data = file_path.read_bytes()
    except OSError:
        return []

    if is_binary_string(data):
        return []
    return scan_text(data.decode("utf-8", errors="ignore"))


def iter_repository_files(root: Path) -> Iterable[Path]:
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [name for name in dirnames if name not in SKIP_DIRS]
        for filename in filenames:
            path = Path(dirpath) / filename
            if path.suffix.lower() in SKIP_SUFFIXES:
                continue
            yield path


def walk_and_scan(root: os.PathLike[str] | str) -> dict[str, list[Finding]]:
    root_path = Path(root).resolve()
    results: dict[str, list[Finding]] = {}
    for path in iter_repository_files(root_path):
        findings = scan_file(path)
        if findings:
            results[str(path.relative_to(root_path))] = findings
    return results


def main() -> int:
    results = walk_and_scan(ROOT)
    if not results:
        print("No concrete credential values detected.")
        return 0

    print("Potential credential values found:")
    for path, items in sorted(results.items()):
        print(f"- {path}")
        for finding in items:
            print(
                f"    - line {finding.line_number}: {finding.kind}: "
                f"{_mask(finding.raw)} (context: {finding.context})"
            )

    print("\nAction: verify each value, remove it from history if real, and rotate it.")
    return 2


if __name__ == "__main__":
    sys.exit(main())
