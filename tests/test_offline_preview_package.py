"""Run: py -3 -m unittest discover -s tests -p test_offline_preview_package.py"""
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import stat
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("offline_preview_builder", ROOT / "scripts" / "build_offline_preview.py")
builder = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(builder)


class OfflinePreviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.raw = builder.read_source(ROOT)
        cls.payloads = builder.make_payloads(cls.raw)
        cls.package = builder.make_zip(cls.payloads)

    def repack(self, entries):
        buffer = io.BytesIO()
        with zipfile.ZipFile(buffer, "w") as archive:
            for name, content, mode in entries:
                info = zipfile.ZipInfo(name)
                info.create_system = 3
                info.external_attr = mode << 16
                archive.writestr(info, content)
        return buffer.getvalue()

    def ordinary_entries(self):
        return [(name, data, stat.S_IFREG | 0o644) for name, data in self.payloads.items()]

    def test_exact_public_source_is_pinned_and_transformations_have_distinct_identity(self):
        self.assertEqual(hashlib.sha256(self.raw).hexdigest(), builder.RAW_HTML_SHA256)
        manifest = builder.validate_archive(self.package, self.payloads)
        self.assertEqual(manifest["source"]["commit"], builder.SOURCE_COMMIT)
        self.assertEqual(manifest["source"]["inputRawHtmlSha256"], builder.digest(self.raw))
        self.assertEqual(manifest["generatedOfflineHtmlSha256"], builder.digest(self.payloads["index.html"]))
        self.assertNotEqual(manifest["generatedOfflineHtmlSha256"], builder.digest(self.raw))
        with self.assertRaises(ValueError):
            builder.make_offline_html(self.raw + b"\n<!-- alternate source -->")

    def test_archive_has_exactly_four_nonexecutable_public_files_and_no_repository(self):
        with zipfile.ZipFile(io.BytesIO(self.package)) as archive:
            self.assertEqual(archive.namelist(), sorted(builder.ALLOWLIST))
            self.assertTrue(all(stat.S_ISREG(info.external_attr >> 16) for info in archive.infolist()))
            self.assertTrue(all(not info.external_attr >> 16 & 0o111 for info in archive.infolist()))

    def test_missing_extra_private_and_executable_entries_are_rejected(self):
        for name in ("DominionOS.exe", "launch.ps1", ".env", ".git/config", "private-key.pem", "src/internal.js", "../index.html", "/index.html", "C:/index.html", "sub\\index.html"):
            with self.subTest(name=name), self.assertRaises(ValueError):
                builder.validate_archive(self.repack(self.ordinary_entries() + [(name, b"extra", stat.S_IFREG | 0o644)]), self.payloads)
        with self.assertRaises(ValueError):
            builder.validate_archive(self.repack(self.ordinary_entries()[:-1]), self.payloads)
        with self.assertRaises(ValueError):
            builder.make_zip({**self.payloads, "launch.bat": b"unsafe"})

    def test_duplicate_and_symbolic_link_entries_are_rejected(self):
        with self.assertWarns(UserWarning):
            duplicate = self.repack(self.ordinary_entries() + [("index.html", b"duplicate", stat.S_IFREG | 0o644)])
        with self.assertRaises(ValueError):
            builder.validate_archive(duplicate, self.payloads)
        symlink = [(name, content, stat.S_IFLNK | 0o777 if name == "index.html" else mode) for name, content, mode in self.ordinary_entries()]
        with self.assertRaises(ValueError):
            builder.validate_archive(self.repack(symlink), self.payloads)
        executable = [(name, content, stat.S_IFREG | 0o755 if name == "index.html" else mode) for name, content, mode in self.ordinary_entries()]
        with self.assertRaises(ValueError):
            builder.validate_archive(self.repack(executable), self.payloads)

    def test_html_boundary_rejects_network_private_credentials_storage_and_forms(self):
        for injection in ("<script>fetch('https://example.invalid')</script>", "<script>new WebSocket('wss://example.invalid')</script>", "<img src='https://example.invalid'>", "<form></form>", "<script>localStorage.setItem('x','y')</script>", "D:\\phi-ops\\private", "-----BEGIN PRIVATE KEY-----", "ghp_" + "A" * 30, '<meta http-equiv="refresh" content="0">'):
            with self.subTest(injection=injection), self.assertRaises(ValueError):
                builder.validate_html(self.raw + injection.encode())

    def test_offline_csp_labels_and_no_automatic_progression(self):
        text = self.payloads["index.html"].decode()
        self.assertIn(f'content="{builder.CSP}"', text)
        self.assertIn("connect-src 'none'", text)
        self.assertIn("const autoplay=false", text)
        self.assertIn("Offline Preview</title>", text)
        self.assertIn("does not include the licensed production runtime or SaaS services", text)
        self.assertNotIn("DOMINION OS™ 1.0", text)

    def test_tampering_with_html_or_manifest_fails_exact_byte_verification(self):
        for target in ("index.html", "demo-manifest.json", "DEMO-TERMS.txt"):
            entries = [(name, content + b" ", mode) if name == target else (name, content, mode) for name, content, mode in self.ordinary_entries()]
            with self.subTest(target=target), self.assertRaises(ValueError):
                builder.validate_archive(self.repack(entries), self.payloads)

    def test_reproducible_build_and_detached_hash_are_bound_to_real_files(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            first = builder.build(ROOT, base / "one")
            second = builder.build(ROOT, base / "two")
            one = (base / "one" / builder.PACKAGE_NAME).read_bytes()
            two = (base / "two" / builder.PACKAGE_NAME).read_bytes()
            self.assertEqual(one, two)
            self.assertEqual(first, second)
            self.assertEqual(first["packageSha256"], builder.digest(one))
            self.assertEqual((base / "one" / f"{builder.PACKAGE_NAME}.sha256").read_text(), f"{builder.digest(one)}  {builder.PACKAGE_NAME}\n")
            for name, content in self.payloads.items():
                self.assertEqual(first["entries"][name]["sha256"], builder.digest(content))
            self.assertFalse(first["googleDeploymentCertified"])
            self.assertFalse(first["nativeProductOrSaasCertification"])
            self.assertIsNone(first["publicUrl"])

    def test_generated_artifacts_cannot_be_written_into_source_repository(self):
        with self.assertRaises(ValueError):
            builder.build(ROOT, ROOT / "generated")

    def test_source_release_record_holds_activation_and_preserves_native_boundaries(self):
        status = json.loads((ROOT / "demo/assets/offline-preview-download.json").read_text())
        self.assertIsNone(status["publicUrl"])
        self.assertIsNone(status["packageSha256"])
        self.assertEqual(status["googleDeployment"]["certification"], "PENDING")
        self.assertFalse(status["nativeDistributionPolicyChanged"])
        native = json.loads((ROOT / "demo/assets/demo-download-package.json").read_text())
        self.assertFalse(native["claimControl"]["binaryDownloadEnabled"])
        self.assertFalse(native["windowsExperience"]["publicDownloadCertified"])


if __name__ == "__main__":
    unittest.main()
