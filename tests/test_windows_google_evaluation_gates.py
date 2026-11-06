"""Negative and baseline tests for the non-deploying Windows/Google claim gate."""
import copy
import json
import unittest
from pathlib import Path
from scripts.verify_windows_google_evaluation_gates import validate

ROOT = Path(__file__).resolve().parents[1]
BASE = json.loads((ROOT / "demo/assets/windows-google-evaluation-readiness.v1.json").read_text())

class ReleaseClaimsTests(unittest.TestCase):
    def expect_rejected(self, edit):
        data = copy.deepcopy(BASE)
        edit(data)
        with self.assertRaises((AssertionError, KeyError, TypeError)):
            validate(data)

    def test_current_releases_are_blocked(self):
        validate(copy.deepcopy(BASE))

    def test_windows_claim_without_receipts(self):
        self.expect_rejected(lambda d: d["windows"].update(publicDownloadCertified=True))

    def test_google_claim_without_receipts(self):
        self.expect_rejected(lambda d: d["google"].update(publicLoginCertified=True))

    def test_binary_url_while_blocked(self):
        self.expect_rejected(lambda d: d["windows"].update(downloadUrl="https://example.com/installer.exe"))

    def test_cloud_url_while_blocked(self):
        self.expect_rejected(lambda d: d["google"].update(loginUrl="https://example.com/trial"))

    def test_public_windows_claim_while_blocked(self):
        self.expect_rejected(lambda d: d["publicClaims"].update(windowsCommercialEvaluationAvailable=True))

    def test_public_google_claim_while_blocked(self):
        self.expect_rejected(lambda d: d["publicClaims"].update(googleCommercialEvaluationAvailable=True))

    def test_upload_while_cloud_blocked(self):
        self.expect_rejected(lambda d: d["google"].update(customerDataUploadsEnabled=True))

    def test_thirteen_modules_claim(self):
        self.expect_rejected(lambda d: d["publicClaims"].update(allThirteenSaaSModulesProductionCertified=True))

    def test_new_platform_is_not_silently_added(self):
        self.expect_rejected(lambda d: d["scope"]["platforms"].append("aws"))

    def test_unsafe_scope(self):
        self.expect_rejected(lambda d: d.update(releasePolicy="OPEN"))

    def test_html_is_not_installer(self):
        self.expect_rejected(lambda d: d["windows"].update(portableSyntheticHtmlIsNotInstaller=False))

if __name__ == "__main__":
    unittest.main()
