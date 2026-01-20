from __future__ import annotations

import argparse
import json
from pathlib import Path

from . import __version__
from .fs import InMemoryFS
from .kernel import Kernel
from .net_installer import install_model
from .process import Process, countdown, writer
from .scheduler import Scheduler


def demo_run(max_ticks: int | None = None, report_path: str | Path = "run-report.json") -> int:
    fs = InMemoryFS()

    # Sample processes
    p1 = Process(1, "countdown", lambda: countdown(3))
    p2 = Process(2, "writer", lambda: writer(fs.write, "/log.txt", "tick", repeats=3))

    k = Kernel(Scheduler())
    k.add_processes([p1, p2])
    ticks = k.run_until_idle(max_ticks=max_ticks)

    # Persist a tiny report
    report = {
        "ticks": ticks,
        "fs": fs.snapshot(),
        "processes": [
            {"pid": p1.pid, "name": p1.name, "state": p1.state, "ticks": p1.ticks},
            {"pid": p2.pid, "name": p2.name, "state": p2.state, "ticks": p2.ticks},
        ],
    }
    out = Path(report_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2))
    return ticks


def build_image() -> Path:
    fs = InMemoryFS()
    fs.write("/etc/dominion.conf", "version=1.0.0")
    fs.write("/boot/hello", "DominionOS bootable demo")

    image = {
        "version": __version__,
        "fs": fs.snapshot(),
        "metadata": {"name": "dominion-os", "kind": "toy-image"},
    }

    build_dir = Path("build")
    build_dir.mkdir(parents=True, exist_ok=True)
    out = build_dir / "image.json"
    out.write_text(json.dumps(image, indent=2))
    return out


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="dominion", description="Dominion OS toy kernel")
    sub = parser.add_subparsers(dest="cmd")

    sub.add_parser("version", help="Show version")

    p_demo = sub.add_parser("demo", help="Demo commands")
    demo_sub = p_demo.add_subparsers(dest="demo_cmd")
    p_run = demo_sub.add_parser("run", help="Run the demo kernel")
    p_run.add_argument("--max-ticks", type=int, default=None, help="Maximum scheduler cycles")
    p_run.add_argument(
        "--report-path",
        type=Path,
        default=Path("run-report.json"),
        help="Destination for the demo run report",
    )

    sub.add_parser("build", help="Build image.json")

    p_net = sub.add_parser("net", help="Install and optimize models")
    net_sub = p_net.add_subparsers(dest="net_cmd")
    p_net_install = net_sub.add_parser("install", help="Install a model manifest")
    p_net_install.add_argument(
        "name",
        nargs="?",
        default="net10",
        help="Model name to install (defaults to net10)",
    )
    p_net_install.add_argument(
        "--target-dir",
        type=Path,
        default=Path("models"),
        help="Root directory for model manifests",
    )
    p_net_install.add_argument(
        "--no-optimize",
        action="store_true",
        help="Skip attaching an optimization profile",
    )
    p_net_install.add_argument(
        "--force",
        action="store_true",
        help="Overwrite an existing manifest",
    )

    args = parser.parse_args(argv)

    if args.cmd == "version":
        print(__version__)
        return 0
    if args.cmd == "demo" and args.demo_cmd == "run":
        ticks = demo_run(max_ticks=args.max_ticks, report_path=args.report_path)
        print(f"Ran demo for {ticks} ticks.")
        return 0
    if args.cmd == "build":
        path = build_image()
        print(f"Built {path}")
        return 0
    if args.cmd == "net" and args.net_cmd == "install":
        manifest = install_model(
            args.name,
            target_dir=args.target_dir,
            optimize=not args.no_optimize,
            force=args.force,
        )
        print(f"Installed {args.name} manifest at {manifest}")
        return 0

    parser.print_help()
    return 2


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
