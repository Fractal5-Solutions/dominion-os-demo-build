import os
import sys
import unittest
from pathlib import Path


class TestDemoBuild(unittest.TestCase):
    def setUp(self):
        self._orig_sys_path = list(sys.path)
        repo_root = Path(__file__).resolve().parents[1]
        sys.path.insert(0, str(repo_root))

        self.cwd = Path.cwd()
        self.tmp = Path(os.getenv("TMP", str(self.cwd))) / "dominion_demo_test"
        if not self.tmp.exists():
            self.tmp.mkdir(parents=True, exist_ok=True)
        os.chdir(self.tmp)

    def tearDown(self):
        os.chdir(self.cwd)
        sys.path[:] = self._orig_sys_path

    def test_demo_build_run(self):
        from demo_build import run_demo

        try:
            dst = run_demo()
            self.assertTrue(dst.exists())
            self.assertTrue((self.tmp / "dist" / "ticks.txt").exists())
        except ModuleNotFoundError:
            raise unittest.SkipTest("Sibling dominion-os-1.0 not available in this environment")

    def test_demo_build_image(self):
        from demo_build import build_image

        try:
            dst = build_image()
            self.assertTrue(dst.exists())
        except ModuleNotFoundError:
            raise unittest.SkipTest("Sibling dominion-os-1.0 not available in this environment")
