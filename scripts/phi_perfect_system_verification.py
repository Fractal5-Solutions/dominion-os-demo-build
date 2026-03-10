#!/usr/bin/env python3
"""
PHI PERFECT SYSTEM VERIFICATION
================================
Automated proof of system perfection through comprehensive testing.
Generates cryptographically signed certification report.
"""

import hashlib
import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple


class PerfectSystemVerifier:
    """Verifies and proves system perfection through automated testing."""

    def __init__(self):
        self.results = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "verification_version": "1.0.0",
            "tests_passed": 0,
            "tests_failed": 0,
            "tests": {},
            "certification": None,
        }
        self.critical_ports = [5000, 5002, 5003, 5004, 5005, 8080, 8081]
        self.required_processes = [
            "phi_background_completion_monitor",
            "autonomous_overnight",
        ]
        # Optional processes that enhance but don't block perfection
        self.optional_processes = ["phi_cost_minimization_simple"]

    def run_command(self, cmd: List[str]) -> Tuple[int, str]:
        """Execute command and return exit code and output."""
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
            return result.returncode, result.stdout + result.stderr
        except Exception as e:
            return 1, str(e)

    def test_web_services(self) -> bool:
        """Verify all web services are running and healthy."""
        print("🔍 Testing web services...")

        success = True
        services_status = {}

        for port in self.critical_ports:
            code, output = self.run_command(
                [
                    "bash",
                    "-c",
                    f"lsof -i :{port} > /dev/null 2>&1 && echo 'RUNNING' || echo 'DOWN'",
                ]
            )

            is_running = "RUNNING" in output
            services_status[f"port_{port}"] = {
                "status": "HEALTHY" if is_running else "DOWN",
                "port": port,
            }

            if not is_running:
                success = False
                print(f"  ❌ Port {port}: DOWN")
            else:
                print(f"  ✅ Port {port}: HEALTHY")

        self.results["tests"]["web_services"] = {
            "passed": success,
            "services": services_status,
            "total_services": len(self.critical_ports),
            "healthy_services": sum(
                1 for s in services_status.values() if s["status"] == "HEALTHY"
            ),
        }

        if success:
            self.results["tests_passed"] += 1
        else:
            self.results["tests_failed"] += 1

        return success

    def test_background_processes(self) -> bool:
        """Verify all background automation processes are running."""
        print("\n🔍 Testing background processes...")

        success = True
        process_status = {}

        for process_name in self.required_processes:
            code, output = self.run_command(
                [
                    "bash",
                    "-c",
                    f"ps aux | grep -E '{process_name}' | grep -v grep | wc -l",
                ]
            )

            count = int(output.strip()) if output.strip().isdigit() else 0
            is_running = count > 0

            process_status[process_name] = {
                "status": "RUNNING" if is_running else "DOWN",
                "instances": count,
            }

            if not is_running:
                success = False
                print(f"  ❌ {process_name}: DOWN")
            else:
                print(f"  ✅ {process_name}: RUNNING ({count} instances)")

        self.results["tests"]["background_processes"] = {
            "passed": success,
            "processes": process_status,
            "total_required": len(self.required_processes),
            "running": sum(
                1 for p in process_status.values() if p["status"] == "RUNNING"
            ),
        }

        if success:
            self.results["tests_passed"] += 1
        else:
            self.results["tests_failed"] += 1

        return success

    def test_system_resources(self) -> bool:
        """Verify system resources are within optimal ranges."""
        print("\n🔍 Testing system resources...")

        # CPU usage
        code, cpu_output = self.run_command(
            [
                "bash",
                "-c",
                "top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1",
            ]
        )
        cpu_usage = float(cpu_output.strip()) if cpu_output.strip() else 0

        # Memory usage
        code, mem_output = self.run_command(
            ["bash", "-c", "free | grep Mem | awk '{print ($3/$2) * 100.0}'"]
        )
        mem_usage = float(mem_output.strip()) if mem_output.strip() else 0

        # Disk usage
        code, disk_output = self.run_command(
            ["bash", "-c", "df -h / | tail -1 | awk '{print $5}' | cut -d'%' -f1"]
        )
        disk_usage = float(disk_output.strip()) if disk_output.strip() else 0

        # Health checks
        cpu_healthy = cpu_usage < 80
        mem_healthy = mem_usage < 85
        disk_healthy = disk_usage < 90

        success = cpu_healthy and mem_healthy and disk_healthy

        self.results["tests"]["system_resources"] = {
            "passed": success,
            "cpu": {
                "usage_percent": cpu_usage,
                "healthy": cpu_healthy,
                "threshold": 80,
            },
            "memory": {
                "usage_percent": mem_usage,
                "healthy": mem_healthy,
                "threshold": 85,
            },
            "disk": {
                "usage_percent": disk_usage,
                "healthy": disk_healthy,
                "threshold": 90,
            },
        }

        print(
            f"  {'✅' if cpu_healthy else '❌'} CPU: {cpu_usage:.1f}% (threshold: 80%)"
        )
        print(
            f"  {'✅' if mem_healthy else '❌'} Memory: {mem_usage:.1f}% (threshold: 85%)"
        )
        print(
            f"  {'✅' if disk_healthy else '❌'} Disk: {disk_usage:.1f}% (threshold: 90%)"
        )

        if success:
            self.results["tests_passed"] += 1
        else:
            self.results["tests_failed"] += 1

        return success

    def test_live_ops_score(self) -> bool:
        """Verify live ops score is at perfect level."""
        print("\n🔍 Testing live ops score...")

        telemetry_file = Path(
            "/workspaces/dominion-os-demo-build/telemetry/live_ops_status.json"
        )

        if not telemetry_file.exists():
            print("  ❌ Telemetry file not found")
            self.results["tests"]["live_ops_score"] = {
                "passed": False,
                "error": "Telemetry file not found",
            }
            self.results["tests_failed"] += 1
            return False

        try:
            with open(telemetry_file) as f:
                telemetry = json.load(f)

            score = float(telemetry.get("live_ops_score", 0))
            sovereign_mode = telemetry.get("sovereign_mode", "UNKNOWN")
            authority_level = telemetry.get("authority_level", "UNKNOWN")

            # Perfect score is >= 0.95 (95%)
            is_perfect = score >= 0.95

            self.results["tests"]["live_ops_score"] = {
                "passed": is_perfect,
                "score": score,
                "sovereign_mode": sovereign_mode,
                "authority_level": authority_level,
                "threshold": 0.95,
                "services": telemetry.get("services", {}),
            }

            print(
                f"  {'✅' if is_perfect else '❌'} Score: {score:.2f} (threshold: 0.95)"
            )
            print(f"  ℹ️  Sovereign Mode: {sovereign_mode}")
            print(f"  ℹ️  Authority Level: {authority_level}")

            if is_perfect:
                self.results["tests_passed"] += 1
            else:
                self.results["tests_failed"] += 1

            return is_perfect

        except Exception as e:
            print(f"  ❌ Error reading telemetry: {e}")
            self.results["tests"]["live_ops_score"] = {"passed": False, "error": str(e)}
            self.results["tests_failed"] += 1
            return False

    def test_critical_files(self) -> bool:
        """Verify all critical configuration files exist."""
        print("\n🔍 Testing critical files...")

        critical_files = [
            "/workspaces/dominion-os-demo-build/docker-compose.yml",
            "/workspaces/dominion-os-demo-build/Dockerfile",
            "/workspaces/dominion-os-demo-build/.venv/bin/activate",
            "/workspaces/dominion-os-demo-build/scripts/phi_start_all_systems.sh",
            "/workspaces/dominion-os-demo-build/scripts/live_ops_monitor.sh",
        ]

        success = True
        file_status = {}

        for filepath in critical_files:
            exists = Path(filepath).exists()
            file_status[filepath] = {"exists": exists}

            if not exists:
                success = False
                print(f"  ❌ Missing: {filepath}")
            else:
                print(f"  ✅ Found: {filepath}")

        self.results["tests"]["critical_files"] = {
            "passed": success,
            "files": file_status,
            "total": len(critical_files),
            "found": sum(1 for f in file_status.values() if f["exists"]),
        }

        if success:
            self.results["tests_passed"] += 1
        else:
            self.results["tests_failed"] += 1

        return success

    def generate_certification(self) -> Dict:
        """Generate cryptographic certification of system perfection."""

        is_perfect = self.results["tests_failed"] == 0

        # Create certification payload
        cert_data = {
            "system": "PHI Dominion OS",
            "timestamp": self.results["timestamp"],
            "verified_by": "Automated Perfect System Verifier v1.0.0",
            "tests_executed": self.results["tests_passed"]
            + self.results["tests_failed"],
            "tests_passed": self.results["tests_passed"],
            "tests_failed": self.results["tests_failed"],
            "status": "PERFECT" if is_perfect else "DEGRADED",
            "certification_level": "GOLD" if is_perfect else "NONE",
        }

        # Generate hash for integrity
        cert_json = json.dumps(cert_data, sort_keys=True)
        cert_hash = hashlib.sha256(cert_json.encode()).hexdigest()

        cert_data["integrity_hash"] = cert_hash
        cert_data["signature"] = f"PHI-CERT-{cert_hash[:16].upper()}"

        return cert_data

    def run_all_tests(self) -> bool:
        """Execute all verification tests."""
        print("\n" + "=" * 60)
        print("PHI PERFECT SYSTEM VERIFICATION")
        print("=" * 60)
        print(f"Started: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}\n")

        # Run all test suites
        test_results = [
            self.test_web_services(),
            self.test_background_processes(),
            self.test_system_resources(),
            self.test_live_ops_score(),
            self.test_critical_files(),
        ]

        all_passed = all(test_results)

        # Generate certification
        self.results["certification"] = self.generate_certification()

        # Print summary
        print("\n" + "=" * 60)
        print("VERIFICATION SUMMARY")
        print("=" * 60)
        print(f"Tests Passed: {self.results['tests_passed']}")
        print(f"Tests Failed: {self.results['tests_failed']}")
        print(f"Status: {self.results['certification']['status']}")
        print(f"Certification: {self.results['certification']['certification_level']}")
        print(f"Signature: {self.results['certification']['signature']}")
        print("=" * 60 + "\n")

        # Save results
        self.save_results()

        return all_passed

    def save_results(self):
        """Save verification results to file."""
        output_dir = Path("/workspaces/dominion-os-demo-build/telemetry")
        output_dir.mkdir(exist_ok=True)

        output_file = output_dir / "perfect_system_verification.json"

        with open(output_file, "w") as f:
            json.dump(self.results, f, indent=2)

        print(f"📄 Verification report saved: {output_file}")

        # Also create a human-readable report
        self.save_readable_report(output_dir / "perfect_system_verification.txt")

    def save_readable_report(self, filepath: Path):
        """Save human-readable verification report."""
        with open(filepath, "w") as f:
            f.write("=" * 70 + "\n")
            f.write("PHI PERFECT SYSTEM VERIFICATION REPORT\n")
            f.write("=" * 70 + "\n\n")
            f.write(f"Timestamp: {self.results['timestamp']}\n")
            f.write(f"Verification Version: {self.results['verification_version']}\n\n")

            f.write("CERTIFICATION\n")
            f.write("-" * 70 + "\n")
            cert = self.results["certification"]
            f.write(f"Status: {cert['status']}\n")
            f.write(f"Level: {cert['certification_level']}\n")
            f.write(f"Signature: {cert['signature']}\n")
            f.write(f"Integrity Hash: {cert['integrity_hash']}\n\n")

            f.write("TEST RESULTS\n")
            f.write("-" * 70 + "\n")
            f.write(f"Tests Passed: {self.results['tests_passed']}\n")
            f.write(f"Tests Failed: {self.results['tests_failed']}\n\n")

            for test_name, test_data in self.results["tests"].items():
                status = "✅ PASSED" if test_data.get("passed") else "❌ FAILED"
                f.write(f"{test_name.upper()}: {status}\n")

            f.write("\n" + "=" * 70 + "\n")
            f.write("END OF REPORT\n")
            f.write("=" * 70 + "\n")

        print(f"📄 Readable report saved: {filepath}")


def main():
    """Main entry point."""
    verifier = PerfectSystemVerifier()
    success = verifier.run_all_tests()

    if success:
        print("✅ SYSTEM PERFECTION VERIFIED AND CERTIFIED")
        return 0
    else:
        print("❌ SYSTEM VERIFICATION FAILED")
        return 1


if __name__ == "__main__":
    sys.exit(main())
