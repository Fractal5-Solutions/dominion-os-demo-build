"""Exact source, archive, public boundary, and deterministic packaging checks."""
import importlib.util
import io
import json
from pathlib import Path
import stat
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("saas_preview", ROOT / "scripts/build_saas_offline_preview.py")
builder = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(builder)


class SaasPreviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.raw, cls.catalogue = builder.read_source(ROOT)
        cls.payloads = builder.make_payloads(cls.raw, cls.catalogue)
        cls.package = builder.archive.make_zip(cls.payloads)

    def repack(self, entries):
        output = io.BytesIO()
        with zipfile.ZipFile(output, "w") as archive:
            for name, content, mode in entries:
                info = zipfile.ZipInfo(name)
                info.create_system = 3
                info.external_attr = mode << 16
                archive.writestr(info, content)
        return output.getvalue()

    def entries(self):
        return [(name, raw, stat.S_IFREG | 0o644) for name, raw in self.payloads.items()]

    def test_source_and_catalogue_are_exact_immutable_git_inputs(self):
        self.assertEqual(builder.archive.digest(self.raw), builder.SOURCE_SHA256)
        self.assertEqual(builder.archive.digest(self.catalogue), builder.CATALOGUE_SHA256)
        self.assertEqual((ROOT / builder.SOURCE_PATH).read_bytes(), self.raw)
        for raw, catalogue in ((self.raw+b" ", self.catalogue), (self.raw, self.catalogue+b" ")):
            with self.assertRaises(ValueError):
                builder.make_payloads(raw, catalogue)

    def test_all_13_identities_and_availability_states_match_catalogue(self):
        samples = builder.validate_source(self.raw, self.catalogue)["modules"]
        canonical = json.loads(self.catalogue)["modules"]
        self.assertEqual(len(samples), 13)
        for sample, module in zip(samples, canonical):
            for key in ("id", "name", "store_state", "implementation_state", "standalone_ga"):
                self.assertEqual(sample[key], module[key])
            self.assertEqual(set(sample["examples"]), {"business", "politics"})
            self.assertFalse(sample["standalone_ga"])
        self.assertEqual(sum(sample["store_state"] == "Coming Soon" for sample in samples), 3)

    def test_exact_four_nonexecutable_ordinary_files_with_bound_manifest(self):
        manifest = builder.archive.validate_archive(self.package, self.payloads)
        with zipfile.ZipFile(io.BytesIO(self.package)) as archive:
            self.assertEqual(archive.namelist(), sorted(builder.archive.ALLOWLIST))
            for info in archive.infolist():
                self.assertTrue(stat.S_ISREG(info.external_attr >> 16))
                self.assertFalse((info.external_attr >> 16) & 0o111)
                self.assertEqual(info.date_time, (1980,1,1,0,0,0))
                self.assertEqual(archive.read(info), self.payloads[info.filename])
        self.assertEqual(manifest["source"]["commit"], builder.SOURCE_COMMIT)
        self.assertEqual(manifest["moduleCount"], 13)
        self.assertFalse(manifest["actualSaasImplementationsIncluded"])
        self.assertFalse(manifest["googleDeploymentCertified"])

    def test_extra_missing_duplicate_paths_and_symlinks_are_rejected(self):
        for name in ("../index.html", "/index.html", "C:/index.html", "sub\\index.html", ".env", ".git/config", "install.ps1", "program.exe"):
            with self.subTest(name=name), self.assertRaises(ValueError):
                builder.archive.validate_archive(self.repack(self.entries()+[(name,b"extra",stat.S_IFREG|0o644)]), self.payloads)
        with self.assertRaises(ValueError):
            builder.archive.validate_archive(self.repack(self.entries()[:-1]), self.payloads)
        with self.assertWarns(UserWarning):
            duplicate = self.repack(self.entries()+[("index.html",b"extra",stat.S_IFREG|0o644)])
        with self.assertRaises(ValueError):
            builder.archive.validate_archive(duplicate, self.payloads)
        for mode in (stat.S_IFLNK|0o777, stat.S_IFREG|0o755):
            entries = [(name,raw,mode if name=="index.html" else original) for name,raw,original in self.entries()]
            with self.assertRaises(ValueError):
                builder.archive.validate_archive(self.repack(entries), self.payloads)

    def test_tampering_with_every_archive_entry_is_rejected(self):
        for target in self.payloads:
            entries = [(name,raw+b" " if name==target else raw,mode) for name,raw,mode in self.entries()]
            with self.subTest(target=target), self.assertRaises(ValueError):
                builder.archive.validate_archive(self.repack(entries), self.payloads)

    def test_reproducible_outputs_and_detached_hash_bind_actual_bytes(self):
        with tempfile.TemporaryDirectory() as temporary:
            first, second = Path(temporary)/"one", Path(temporary)/"two"
            a, b = builder.build(ROOT,first), builder.build(ROOT,second)
            self.assertEqual(a,b)
            self.assertEqual((first/builder.PACKAGE_NAME).read_bytes(), (second/builder.PACKAGE_NAME).read_bytes())
            self.assertEqual(a["packageSha256"], builder.archive.digest(self.package))
            self.assertEqual((first/(builder.PACKAGE_NAME+".sha256")).read_text(), a["packageSha256"]+"  "+builder.PACKAGE_NAME+"\n")
            self.assertEqual(a["malwareScan"], "NOT_PERFORMED_BY_PACKAGER")
            self.assertEqual(a["browserFileAcceptance"], "NOT_PERFORMED_BY_PACKAGER")
            self.assertFalse(a["googleDeploymentCertified"])

    def test_output_inside_repository_is_prohibited(self):
        with self.assertRaises(ValueError):
            builder.build(ROOT, ROOT/"generated")

    def test_existing_os_source_identity_and_download_hold_are_preserved(self):
        raw = builder.archive.read_source(ROOT)
        os_payloads = builder.archive.make_payloads(raw)
        self.assertEqual(builder.archive.digest(builder.archive.make_zip(os_payloads)), "217a05da190afa101a4df10acd19ef84b12f139579a34b6377900d757f045bbf")
        status=json.loads((ROOT/"demo/assets/saas-offline-preview-download.json").read_text())
        self.assertEqual(status["status"], "PENDING_GOOGLE_CERTIFICATION")
        self.assertIsNone(status["publicUrl"])
        self.assertIsNone(status["packageSha256"])
        self.assertFalse(status["nativeDistributionPolicyChanged"])
        self.assertFalse(status["actualSaasImplementationIncluded"])


if __name__ == "__main__":
    unittest.main()
