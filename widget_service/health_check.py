#!/usr/bin/env python3
import requests
import sys

try:
    r = requests.get('http://127.0.0.1:8080/health', timeout=5)
    if r.status_code == 200 and 'healthy' in r.text:
        sys.exit(0)
    else:
        sys.exit(1)
except Exception:
    sys.exit(1)
