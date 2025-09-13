from __future__ import annotations

import json
import re
from pathlib import Path


def check_catalog() -> dict:
    p = Path("web/sqsp/f5-applications.code.html")
    if not p.exists():
        return {"exists": False, "no_external": False}
    html = p.read_text(encoding="utf-8")
    externals = re.findall(r'href="https?://', html)
    return {"exists": True, "no_external": len(externals) == 0}


def check_canon() -> bool:
    return Path("docs/canon_seal.md").exists()


def main() -> int:
    cat = check_catalog()
    snap = {"catalog": cat, "canon": check_canon(), "ok": cat.get("exists") and cat.get("no_external")}
    Path("demo_success_snapshot.json").write_text(json.dumps(snap, indent=2))
    print(json.dumps(snap))
    return 0 if snap["ok"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
