"""Protect the production-accepted v4.4 interaction surface in staged v4.5."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = (ROOT / "squarespace/demo-1-v4-4-production-preflight.html").read_text(encoding="utf-8")
CANDIDATE = (ROOT / "squarespace/demo-1-v4-5-windows-google-release-candidate.html").read_text(encoding="utf-8")

def ids(text):
    return set(re.findall(r'\\bid="([^"]+)"', text))

class DemoCandidateTests(unittest.TestCase):
    def test_canonical_dom_ids_preserved(self):
        self.assertEqual(ids(BASE), ids(CANDIDATE))

    def test_live_interface_features_preserved(self):
        for signal in ["Business", "Politics", "Download", "<script", "</script>", "mission", "reset", "Google Cloud"]:
            self.assertIn(signal, CANDIDATE)
        self.assertEqual(BASE.count("<script"), CANDIDATE.count("<script"))
        self.assertEqual(BASE.count("</script>"), CANDIDATE.count("</script>"))

    def test_links_preserved(self):
        existing = set(re.findall(r'href="([^"]+)"', BASE))
        candidate = set(re.findall(r'href="([^"]+)"', CANDIDATE))
        self.assertTrue(existing.issubset(candidate), existing-candidate)

    def test_new_scope_not_misrepresented(self):
        self.assertIn("Google Workspace", CANDIDATE)
        self.assertIn("Windows x64", CANDIDATE)
        self.assertIn("seven-day signed/revocable", CANDIDATE)
        self.assertIn("not a certified public login", CANDIDATE)
        self.assertIn("No actual customer data", CANDIDATE)
        self.assertIn("demo-1-v4.5-20261106-windows-google-release-candidate", CANDIDATE)

    def test_squarespace_publisher_boundary(self):
        self.assertIn("principal pastes and publishes", CANDIDATE)
        self.assertIn("Do NOT interpret", CANDIDATE)

if __name__ == "__main__":
    unittest.main()
