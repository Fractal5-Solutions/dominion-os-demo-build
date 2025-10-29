from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import sys


def _add_sibling_os_to_syspath() -> None:
    here = Path(__file__).resolve().parent
    # Prefer explicit env var, else sibling path
    env_path = os.getenv("DOMINION_OS_PATH")
    if env_path:
        os_repo = Path(env_path)
    else:
        os_repo = here.parent / "dominion-os-1.0"
    pkg_path = os_repo / "dominion_os"
    if pkg_path.exists():
        sys.path.insert(0, str(os_repo))


def run_demo() -> Path:
    _add_sibling_os_to_syspath()
    from dominion_os.cli import demo_run  # type: ignore

    out_dir = Path("dist")
    out_dir.mkdir(parents=True, exist_ok=True)

    ticks = demo_run()
    # move report into dist/
    src = Path("run-report.json")
    dst = out_dir / "run-report.json"
    if src.exists():
        dst.write_text(src.read_text())
        src.unlink()
    (out_dir / "ticks.txt").write_text(str(ticks))
    return dst


def build_demo_image() -> Path:
    _add_sibling_os_to_syspath()
    from dominion_os.cli import build_image as os_build_image  # type: ignore

    path = os_build_image()
    out_dir = Path("dist")
    out_dir.mkdir(parents=True, exist_ok=True)
    dst = out_dir / path.name
    dst.write_text(Path(path).read_text())
    return dst


# Backwards-compat alias for tests and docs
def build_image() -> Path:  # pragma: no cover - thin wrapper
    return build_demo_image()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Dominion demo build")
    sub = parser.add_subparsers(dest="cmd")
    sub.add_parser("run")
    sub.add_parser("build")

    p_cc = sub.add_parser("command-core", help="Run Command Core orchestration demo")
    p_cc.add_argument(
        "--duration", type=int, default=120, help="Scheduler ticks to run"
    )
    p_cc.add_argument("--scale", choices=["small", "medium", "large"], default="small")
    p_cc.add_argument(
        "--no-ui", action="store_true", help="Headless run; write artifacts only"
    )
    p_cc.add_argument(
        "--refresh-ms", type=int, default=0, help="UI refresh delay in ms"
    )

    p_auto = sub.add_parser("autopilot", help="Fully automated NHITL orchestration run")
    p_auto.add_argument("--duration", type=int, default=180, help="Ticks per run")
    p_auto.add_argument(
        "--scale", choices=["small", "medium", "large"], default="large"
    )
    p_auto.add_argument("--runs", type=int, default=1, help="Number of sequential runs")
    p_auto.add_argument("--interval-ms", type=int, default=0, help="Pause between runs")

    p_flag = sub.add_parser(
        "flagship", help="Build OS + run Command Core + package artifacts"
    )
    p_flag.add_argument(
        "--duration", type=int, default=300, help="Ticks to run Command Core"
    )
    p_flag.add_argument(
        "--scale", choices=["small", "medium", "large"], default="large"
    )
    p_flag.add_argument(
        "--no-ui", action="store_true", help="Run headless (recommended for CI)"
    )
    p_flag.add_argument(
        "--refresh-ms", type=int, default=0, help="UI refresh delay in ms (interactive)"
    )
    args = parser.parse_args(argv)

    if args.cmd == "run":
        dst = run_demo()
        print(f"Demo report: {dst}")
        return 0
    if args.cmd == "build":
        dst = build_demo_image()
        print(f"Image: {dst}")
        return 0
    if args.cmd == "command-core":
        _add_sibling_os_to_syspath()
        from command_core import run_command_core

        out = run_command_core(
            duration_ticks=args.duration,
            scale=args.scale,
            refresh_ms=args.refresh_ms,
            ui=(not args.no_ui),
        )
        print("Command Core summary:", out)
        return 0
    if args.cmd == "autopilot":
        _add_sibling_os_to_syspath()
        from command_core import run_command_core
        import time, json
        from datetime import datetime

        results = []
        for i in range(args.runs):
            print(
                f"[autopilot] Run {i+1}/{args.runs}: scale={args.scale} duration={args.duration}"
            )
            res = run_command_core(
                duration_ticks=args.duration, scale=args.scale, ui=False
            )
            results.append(res)
            if i < args.runs - 1 and args.interval_ms:
                time.sleep(args.interval_ms / 1000)
        # Write flight summary
        out_dir = Path("dist") / "command_core"
        out_dir.mkdir(parents=True, exist_ok=True)
        stamp = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
        flight = out_dir / f"flight_{stamp}.json"
        flight.write_text(json.dumps({"runs": results}, indent=2))
        print(f"[autopilot] Completed. Flight log: {flight}")
        return 0

    if args.cmd == "flagship":
        # Ensure sibling OS is importable
        _add_sibling_os_to_syspath()
        # 1) Build OS image from dominion-os-1.0
        try:
            from dominion_os.cli import build_image as os_build_image  # type: ignore
        except ModuleNotFoundError:
            print(
                "Error: dominion_os not found. Set DOMINION_OS_PATH or place sibling repo."
            )
            return 1
        os_image = os_build_image()
        print(f"[flagship] Built OS image: {os_image}")

        # 2) Run Command Core
        from command_core import run_command_core

        session = run_command_core(
            duration_ticks=args.duration,
            scale=args.scale,
            refresh_ms=args.refresh_ms,
            ui=(not args.no_ui),
        )
        print("[flagship] Command Core session:", session)

        # 3) Package artifacts
        from datetime import datetime
        import zipfile

        dist = Path("dist")
        cc_dir = dist / "command_core"
        pkg_dir = dist / "flagship"
        pkg_dir.mkdir(parents=True, exist_ok=True)
        stamp = datetime.utcnow().strftime("%Y%m%dT%H%M%S")
        pkg_path = pkg_dir / f"dominion_flagship_{args.scale}_{stamp}.zip"
        with zipfile.ZipFile(pkg_path, "w", compression=zipfile.ZIP_DEFLATED) as z:
            # Include OS image
            if Path(os_image).exists():
                z.write(os_image, arcname=f"os/{Path(os_image).name}")
            # Include Command Core artifacts
            if cc_dir.exists():
                for p in cc_dir.glob("*"):
                    z.write(p, arcname=f"command_core/{p.name}")
        print(f"[flagship] Packaged artifacts: {pkg_path}")
        return 0

    parser.print_help()
    return 2


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
