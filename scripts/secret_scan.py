#!/usr/bin/env python3
"""High-confidence repository secret scanner with redacted output."""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKIP_DIRS = {'.git', '.venv', 'venv', 'node_modules', '__pycache__', 'backups', 'out'}
SKIP_SUFFIXES = {'.png', '.jpg', '.jpeg', '.gif', '.zip', '.tar', '.whl', '.pyc'}
PLACEHOLDERS = {'REDACTED', 'CHANGEME', 'CHANGE_ME', 'EXAMPLE', 'PLACEHOLDER', 'YOUR_SECRET_HERE'}

PATTERNS = {
    'GitHub token': re.compile(r'\b(?:ghp|github_pat)_[0-9A-Za-z_]{20,}\b'),
    'Stripe secret': re.compile(r'\bsk_(?:live|test)_[0-9A-Za-z_-]{16,}\b'),
    'Google API key': re.compile(r'\bAIza[0-9A-Za-z_-]{35}\b'),
    'AWS access key': re.compile(r'\bAKIA[0-9A-Z]{16}\b'),
    'Slack token': re.compile(r'\bxox[baprs]-[A-Za-z0-9-]{10,}\b'),
    'Private key header': re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
}
ASSIGNMENT = re.compile(
    r'(?im)^\s*(?:export\s+)?(?:[A-Z0-9_]*(?:PASSWORD|PASSPHRASE|TOKEN|SECRET|API_KEY|PRIVATE_KEY)[A-Z0-9_]*)\s*[=:]\s*["\']?([^\s"\'`#]{12,})'
)


def is_placeholder(value: str) -> bool:
    normalized = value.strip().strip('"\'').upper()
    return normalized in PLACEHOLDERS or normalized.startswith('${') or normalized.startswith('{{')


def redacted_context(text: str, start: int, end: int) -> str:
    left = max(0, start - 24)
    right = min(len(text), end + 24)
    return (text[left:start] + '<redacted>' + text[end:right]).replace('\n', ' ')[:160]


def scan_file(path: Path):
    try:
        data = path.read_bytes()
    except OSError:
        return []
    if b'\x00' in data:
        return []
    text = data.decode('utf-8', errors='ignore')
    findings = []
    for name, pattern in PATTERNS.items():
        for match in pattern.finditer(text):
            findings.append((name, redacted_context(text, match.start(), match.end())))
    for match in ASSIGNMENT.finditer(text):
        value = match.group(1)
        if not is_placeholder(value):
            findings.append(('Assigned secret value', redacted_context(text, match.start(1), match.end(1))))
    return findings


def main() -> int:
    results = {}
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [name for name in dirnames if name not in SKIP_DIRS]
        for filename in filenames:
            path = Path(dirpath) / filename
            if path.suffix.lower() in SKIP_SUFFIXES:
                continue
            findings = scan_file(path)
            if findings:
                results[str(path.relative_to(ROOT))] = findings

    if not results:
        print('No high-confidence secrets detected.')
        return 0

    print('Potential secrets found; values are redacted:')
    for path, findings in sorted(results.items()):
        print(f'- {path}')
        for name, context in findings:
            print(f'    - {name} (context: {context})')
    print('\nAction: rotate any confirmed credential and remove it from repository history.')
    return 2


if __name__ == '__main__':
    sys.exit(main())
