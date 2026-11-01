"""Pure allowlist regression tests; no browser or network required."""
import importlib.util
from pathlib import Path
import unittest

MODULE = Path(__file__).with_name("fractal5_live_demo_qa.py")
spec = importlib.util.spec_from_file_location("fractal5_demo_qa", MODULE)
qa = importlib.util.module_from_spec(spec)
spec.loader.exec_module(qa)

class AllowedUrlTests(unittest.TestCase):
    def test_exact_public_page(self):
        self.assertTrue(qa.approved("https://www.fractal5solutions.com/demo-1"))
    def test_https_asset(self):
        self.assertTrue(qa.approved("https://static1.squarespace.com/a.js"))
    def test_reject_http(self):
        self.assertFalse(qa.approved("http://www.fractal5solutions.com/demo-1"))
    def test_reject_lookalike_domain(self):
        self.assertFalse(qa.approved("https://www.fractal5solutions.com.evil.example/a"))
    def test_reject_arbitrary_network(self):
        self.assertFalse(qa.approved("https://example.org/data"))
    def test_reject_credentials(self):
        self.assertFalse(qa.approved("https://name:password@www.fractal5solutions.com/demo-1"))
    def test_reject_nonstandard_https_port(self):
        self.assertFalse(qa.approved("https://www.fractal5solutions.com:8443/demo-1"))
    def test_malformed_port_fails_closed(self):
        self.assertFalse(qa.approved("https://www.fractal5solutions.com:bad/demo-1"))
    def test_invalid_ipv6_fails_closed(self):
        self.assertFalse(qa.approved("https://[not-an-ipv6/demo-1"))
    def test_expected_receipt_checks_are_unique(self):
        self.assertEqual(len(qa.CHECK_NAMES), len(set(qa.CHECK_NAMES)))

if __name__ == "__main__":
    unittest.main()
