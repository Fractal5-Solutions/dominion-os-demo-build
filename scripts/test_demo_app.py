import unittest

from demo_app import app


class DemoAppTestCase(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_home(self):
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data["status"], "operational")
        self.assertEqual(data["sovereign_power_mode"], "9/9")
        self.assertEqual(data["authority_level"], "maximum")

    def test_health(self):
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data["status"], "healthy")
        self.assertEqual(data["sovereignty"], "maintained")
        self.assertEqual(data["power_mode"], "maximum")

    def test_sovereign(self):
        response = self.client.get("/sovereign")
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data["sovereign_status"], "ACTIVE")
        self.assertEqual(data["authority_level"], "9/9")
        self.assertEqual(data["data_residency"], "sovereign_controlled")
        self.assertIn("optimization", data)

    def test_channels(self):
        response = self.client.get("/channels")
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data["monitoring_status"], "active")
        self.assertEqual(data["sovereign_control"], "enabled")
        squarespace = None
        for ch in data["marketing_channels"]:
            if ch["name"] == "Squarespace":
                squarespace = ch
                break
        self.assertIsNotNone(squarespace, "Squarespace channel not found")
        if squarespace:
            self.assertEqual(squarespace["status"], "monitored")


if __name__ == "__main__":
    unittest.main()
