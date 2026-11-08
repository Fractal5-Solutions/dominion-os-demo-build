"""Negative tests for the limited public-download manifest checker.

These tests use only temporary synthetic manifest copies. They neither sign nor
publish binaries, and deliberately do not run network or Windows installation.
"""
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
ASSETS = (
    "demo/assets/demo-download-package.json",
    "demo/assets/dominion-product-manifest.v1.json",
    "demo/assets/dominion-saas-catalog.json",
    "demo/live-mission-demo.html",
)
SCRIPT = "scripts/verify_public_demo_gates.py"


class PublicDownloadFailClosedTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = pathlib.Path(self.temp.name)
        for relative in (*ASSETS, SCRIPT):
            destination = self.root / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / relative, destination)

    def check_gate(self, mutate=None):
        manifest_path = self.root / "demo/assets/demo-download-package.json"
        if mutate:
            data = json.loads(manifest_path.read_text(encoding="utf-8"))
            mutate(data)
            manifest_path.write_text(json.dumps(data), encoding="utf-8")
        return subprocess.run(
            [sys.executable, str(self.root / SCRIPT)],
            cwd=self.root,
            text=True,
            capture_output=True,
            timeout=30,
            check=False,
        )

    def test_current_unsigned_binary_remains_disabled(self):
        result = self.check_gate()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("PASS (limited static gates)", result.stdout)

    def test_self_asserted_verified_signature_cannot_enable_download(self):
        def mutate(data):
            data["windowsExperience"]["authenticode"] = "VERIFIED"
            data["windowsExperience"]["publicDownloadCertified"] = True
        result = self.check_gate(mutate)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Common Windows public download withheld", result.stdout)

    def test_binary_activation_cannot_bypass_uncertified_manifest(self):
        def mutate(data):
            data["claimControl"]["binaryDownloadEnabled"] = True
        result = self.check_gate(mutate)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("binary-download control remains disabled", result.stdout)

    def test_politics_binary_remains_withheld(self):
        def mutate(data):
            data["politicsExperience"]["downloadable"] = True
        result = self.check_gate(mutate)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Politics binary download", result.stdout)


if __name__ == "__main__":
    unittest.main()
