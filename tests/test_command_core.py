"""Tests for command_core.py module."""

import json
import unittest
from pathlib import Path


class TestCommandCore(unittest.TestCase):
    """Test suite for command core functionality."""

    def test_command_core_imports(self):
        """Verify command_core can be imported."""
        try:
            import command_core

            self.assertIsNotNone(command_core)
        except ModuleNotFoundError:
            raise unittest.SkipTest("Sibling dominion-os-1.0 not available")

    def test_command_core_dashboard(self):
        """Test dashboard generation function exists."""
        try:
            from command_core import render_dashboard

            self.assertTrue(callable(render_dashboard))
        except (ModuleNotFoundError, ImportError):
            raise unittest.SkipTest("Sibling dominion-os-1.0 not available")


class TestConfigurations(unittest.TestCase):
    """Test suite for configuration files."""

    def test_sovereign_config_valid_json(self):
        """Verify sovereign-config.json is valid JSON."""
        config_path = Path("config/sovereign-config.json")
        if not config_path.exists():
            raise unittest.SkipTest("Config file not found")

        with open(config_path) as f:
            config = json.load(f)

        self.assertIsInstance(config, dict)
        self.assertIn("sovereign_mode", config)

    def test_ai_gates_config_valid_json(self):
        """Verify ai_gates.json is valid JSON."""
        config_path = Path("config/ai_gates.json")
        if not config_path.exists():
            raise unittest.SkipTest("Config file not found")

        with open(config_path) as f:
            config = json.load(f)

        self.assertIsInstance(config, dict)

    def test_nhitl_oversight_config_valid_json(self):
        """Verify nhitl_oversight.json is valid JSON."""
        config_path = Path("config/nhitl_oversight.json")
        if not config_path.exists():
            raise unittest.SkipTest("Config file not found")

        with open(config_path) as f:
            config = json.load(f)

        self.assertIsInstance(config, dict)


class TestFlightLogs(unittest.TestCase):
    """Test suite for autopilot flight logs."""

    def test_flight_logs_exist(self):
        """Verify flight logs directory exists."""
        flight_dir = Path("dist/command_core")
        if not flight_dir.exists():
            raise unittest.SkipTest("Flight logs directory not found")

        self.assertTrue(flight_dir.is_dir())

    def test_latest_flight_log_valid(self):
        """Verify latest flight log is valid JSON."""
        flight_dir = Path("dist/command_core")
        if not flight_dir.exists():
            raise unittest.SkipTest("Flight logs directory not found")

        flight_logs = sorted(flight_dir.glob("flight_*.json"))
        if not flight_logs:
            raise unittest.SkipTest("No flight logs found")

        latest_log = flight_logs[-1]
        with open(latest_log) as f:
            flight = json.load(f)

        self.assertIsInstance(flight, dict)
        self.assertIn("runs", flight)
        self.assertIsInstance(flight["runs"], list)

        if flight["runs"]:
            run = flight["runs"][0]
            self.assertIn("scale", run)
            self.assertIn("processed", run)


if __name__ == "__main__":
    unittest.main()
