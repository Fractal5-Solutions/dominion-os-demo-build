#!/usr/bin/env python3
"""
Lightweight repository secret scanner used by CI and pre-commit.
Exits with code 1 if any suspicious matches are found.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(__file__))

SKIP_DIRS = {'.git', '.venv', 'venv', 'node_modules', '__pycache__'}

PATTERNS = {
    'GitHub PAT': re.compile(r'ghp_[0-9A-Za-z_]{36}'),
    'Stripe secret (sk_live/test)': re.compile(r'sk_(live|test)_[0-9A-Za-z_-]{16,}'),
    'Google API key': re.compile(r'AIza[0-9A-Za-z-_]{35}'),
    'AWS Access Key': re.compile(r'AKIA[0-9A-Z]{16}'),
    'Slack token': re.compile(r'xox[baprs]-[A-Za-z0-9-]+'),
    'Private key header': re.compile(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
    'SSH public key (ssh-rsa)': re.compile(r'^ssh-rsa\b'),
    'Generic secret var': re.compile(r'(?i)\b(api[_-]?key|apikey|client[_-]?secret|secret[_-]?key|oauth[_-]?client[_-]?secret|jwt[_-]?secret|github[_-]?token|password|passphrase)\b'),
}

def is_binary_string(bytesdata: bytes) -> bool:
    # Heuristic: NUL byte or over 30% non-printable
    if b"\x00" in bytesdata:
        return True
    text = bytesdata.decode('utf-8', errors='ignore')
    non_print = sum(1 for c in text if ord(c) < 9 or (ord(c) > 13 and ord(c) < 32))
    return (non_print / max(1, len(text))) > 0.3


def scan_file(path):
    try:
        with open(path, 'rb') as f:
            data = f.read()
    except Exception:
        return []

    if is_binary_string(data):
        return []

    text = data.decode('utf-8', errors='ignore')
    findings = []
    for name, pattern in PATTERNS.items():
        for m in pattern.finditer(text):
            # Record a short masked snippet
            start = max(0, m.start() - 20)
            end = min(len(text), m.end() + 20)
            snippet = text[start:end].replace('\n', ' ')[:200]
            findings.append((name, m.group(0), snippet))
    return findings


def walk_and_scan(root):
    results = {}
    for dirpath, dirnames, filenames in os.walk(root):
        # prune
        parts = set(dirpath.replace(root, '').split(os.sep))
        if parts & SKIP_DIRS:
            continue
        # mutate dirnames in-place to skip certain dirs
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]

        for fn in filenames:
            # skip large vendor directories by name
            if fn.endswith(('.png', '.jpg', '.jpeg', '.gif', '.zip', '.tar', '.whl')):
                continue
            path = os.path.join(dirpath, fn)
            rel = os.path.relpath(path, root)
            findings = scan_file(path)
            if findings:
                results[rel] = findings
    return results


def main():
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    results = walk_and_scan(repo_root)
    if not results:
        print('No suspicious secrets detected.')
        return 0

    print('Potential secrets found:')
    for path, items in results.items():
        print(f'- {path}')
        for name, raw, snippet in items:
            masked = raw[:4] + '...' if len(raw) > 8 else raw
            print(f'    - {name}: {masked} (context: {snippet})')

    print('\nAction: Do not merge or deploy until findings are reviewed and rotated.')
    return 2


if __name__ == '__main__':
    rc = main()
    sys.exit(rc)
