import importlib
import os
import sys
import unittest
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))


class TestDemoBuild(unittest.TestCase):
    def setUp(self):
        self.cwd = Path.cwd()
        self.tmp = Path(os.getenv("TMP", str(self.cwd))) / "dominion_demo_test"
        if not self.tmp.exists():
            self.tmp.mkdir(parents=True, exist_ok=True)
        os.chdir(self.tmp)

    def tearDown(self):
        os.chdir(self.cwd)

    def test_demo_build_run(self):
        try:
            module = importlib.import_module("demo_build")
            run_demo = module.run_demo  # type: ignore[attr-defined]
            dst = run_demo()
            self.assertTrue(dst.exists())
            self.assertTrue((self.tmp / "dist" / "ticks.txt").exists())
        except ModuleNotFoundError as err:
            raise unittest.SkipTest(
                "Sibling dominion-os-1.0 not available in this environment"
            ) from err

    def test_demo_build_image(self):
        try:
            module = importlib.import_module("demo_build")
            build_image = module.build_image  # type: ignore[attr-defined]
            dst = build_image()
            self.assertTrue(dst.exists())
        except ModuleNotFoundError as err:
            raise unittest.SkipTest(
                "Sibling dominion-os-1.0 not available in this environment"
            ) from err
