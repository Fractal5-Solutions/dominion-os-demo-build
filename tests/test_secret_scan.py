from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from scripts import secret_scan


class SecretScanTests(unittest.TestCase):
    def test_concrete_token_formats_are_detected_and_redacted(self) -> None:
        github_token = "ghp_" + "A" * 36
        openai_key = "sk-proj-" + "B" * 32
        findings = secret_scan.scan_text(
            f"GITHUB_TOKEN={github_token}\nOPENAI_API_KEY={openai_key}\n"
        )

        kinds = {finding.kind for finding in findings}
        self.assertIn("GitHub token", kinds)
        self.assertIn("OpenAI API key", kinds)
        for finding in findings:
            self.assertNotIn(finding.raw, finding.context)
            self.assertIn("...", secret_scan._mask(finding.raw))

    def test_real_generic_assignment_is_detected(self) -> None:
        findings = secret_scan.scan_text(
            'DATABASE_PASSWORD="C0rrect-Horse_Battery9!"\n'
        )
        self.assertEqual(len(findings), 1)
        self.assertTrue(findings[0].kind.startswith("Credential assignment"))

    def test_placeholders_templates_and_secret_references_are_ignored(self) -> None:
        text = "\n".join(
            [
                "GITHUB_TOKEN=ghp_your_github_token_here",
                "STRIPE_SECRET_KEY=sk_live_your_stripe_secret_key_here",
                "POSTGRES_PASSWORD=change_this_secure_password",
                "OAUTH_CLIENT_SECRET=your_oauth_client_secret",
                "FINALIZER_TOKEN=${{ secrets.FINALIZER_TOKEN }}",
                "AUTH_TOKEN=$GITHUB_TOKEN",
                "REDIS_PASSWORD=",
                "GCP_SERVICE_ACCOUNT_KEY_PATH=/secrets/gcp-key.json",
            ]
        )
        self.assertEqual(secret_scan.scan_text(text), [])

    def test_secret_vocabulary_and_detection_rules_are_not_findings(self) -> None:
        text = "\n".join(
            [
                "Rotate the password before production deployment.",
                "The OAuth client secret is stored in Secret Manager.",
                "PATTERNS = ('JWT_SECRET', 'PASSWORD=', 'API_KEY')",
                "gcloud secrets create github-oauth-client-secret --project demo",
            ]
        )
        self.assertEqual(secret_scan.scan_text(text), [])

    def test_repository_credential_templates_are_clean(self) -> None:
        for relative_path in (".env.desktop-pro", ".env.mcp.template"):
            with self.subTest(relative_path=relative_path):
                self.assertEqual(
                    secret_scan.scan_file(secret_scan.ROOT / relative_path),
                    [],
                )

    def test_binary_and_large_files_are_skipped(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            binary = root / "binary.dat"
            binary.write_bytes(b"\x00ghp_" + b"A" * 36)
            self.assertEqual(secret_scan.scan_file(binary), [])


if __name__ == "__main__":
    unittest.main()
