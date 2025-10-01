import json
import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parents[1]
if str(PROJECT_DIR) not in sys.path:
    sys.path.insert(0, str(PROJECT_DIR))

import demo_build
from command_core import run_command_core
from dominion_os import cli as os_cli


class TestDemoBuild(unittest.TestCase):
    def setUp(self) -> None:
        self.original_cwd = Path.cwd()
        self.tmpdir = Path(tempfile.mkdtemp(prefix="dominion_demo_test_"))
        os.chdir(self.tmpdir)

    def tearDown(self) -> None:
        os.chdir(self.original_cwd)
        shutil.rmtree(self.tmpdir, ignore_errors=True)

    def test_run_demo_produces_report(self) -> None:
        report_path = demo_build.run_demo()
        self.assertTrue(report_path.exists(), "run report should exist")
        ticks_file = Path("dist") / "ticks.txt"
        self.assertTrue(ticks_file.exists(), "ticks file should exist")
        data = json.loads(report_path.read_text())
        self.assertEqual(data["ticks"], int(ticks_file.read_text()))
        self.assertGreater(data["metrics"]["processed"], 0)

    def test_build_demo_image_copies_payload(self) -> None:
        image_path = demo_build.build_demo_image()
        self.assertTrue(image_path.exists(), "image payload should exist")
        payload = json.loads(image_path.read_text())
        self.assertEqual(payload["version"], os_cli.VERSION)

    def test_command_core_headless_run(self) -> None:
        summary = run_command_core(duration_ticks=5, ui=False, outdir=Path("artifacts"))
        self.assertEqual(summary["ticks"], 5)
        events_path = Path("artifacts") / "events.log"
        self.assertTrue(events_path.exists())
        self.assertIn("services", summary)


if __name__ == "__main__":
    unittest.main()
