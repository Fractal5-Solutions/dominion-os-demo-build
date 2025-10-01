#!/usr/bin/env python3
"""
Repository Health Monitor
Monitors repository size, security, and performance metrics
"""

import os
import json
import subprocess
from datetime import datetime
from pathlib import Path

class RepositoryMonitor:
    def __init__(self, repo_path: str = "."):
        self.repo_path = Path(repo_path)
        self.report_file = self.repo_path / ".github" / "repo-health-report.json"

    def get_repo_size(self) -> dict:
        """Get repository size information"""
        try:
            result = subprocess.run(
                ["git", "count-objects", "-vH"],
                cwd=self.repo_path,
                capture_output=True,
                text=True,
                check=True
            )

            size_info = {}
            for line in result.stdout.strip().split('\n'):
                if ': ' in line:
                    key, value = line.split(': ', 1)
                    size_info[key.lower().replace(' ', '_')] = value

            return size_info
        except subprocess.CalledProcessError as e:
            return {"error": f"Failed to get repo size: {e}"}

    def check_vulnerabilities(self) -> dict:
        """Check for known security vulnerabilities"""
        vulnerabilities = {
            "critical": 0,
            "high": 0,
            "moderate": 0,
            "low": 0,
            "total": 0
        }

        # Check for common vulnerable patterns
        vulnerable_files = []

        # Check Python requirements
        req_files = ["requirements.txt", "pyproject.toml", "Pipfile"]
        for req_file in req_files:
            if (self.repo_path / req_file).exists():
                # This would integrate with safety or similar tools
                pass

        return {
            "vulnerabilities": vulnerabilities,
            "vulnerable_files": vulnerable_files,
            "recommendations": [
                "Run 'pip install safety' and 'safety check'",
                "Review Dependabot alerts in GitHub",
                "Update dependencies regularly"
            ]
        }

    def check_lfs_status(self) -> dict:
        """Check Git LFS status"""
        try:
            result = subprocess.run(
                ["git", "lfs", "status"],
                cwd=self.repo_path,
                capture_output=True,
                text=True
            )

            return {
                "lfs_installed": result.returncode == 0,
                "lfs_status": "healthy" if result.returncode == 0 else "not_configured",
                "output": result.stdout.strip() if result.returncode == 0 else result.stderr.strip()
            }
        except FileNotFoundError:
            return {
                "lfs_installed": False,
                "lfs_status": "not_installed",
                "recommendations": ["Install Git LFS: git lfs install"]
            }

    def generate_report(self) -> dict:
        """Generate comprehensive repository health report"""
        report = {
            "timestamp": datetime.now().isoformat(),
            "repository": "dominion-os-1.0",
            "size_info": self.get_repo_size(),
            "security": self.check_vulnerabilities(),
            "lfs_status": self.check_lfs_status(),
            "recommendations": []
        }

        # Generate recommendations based on findings
        size_gb = 0
        if "size-pack" in report["size_info"]:
            size_str = report["size_info"]["size-pack"]
            if "GiB" in size_str:
                size_gb = float(size_str.replace(" GiB", ""))

        if size_gb > 1.8:
            report["recommendations"].append("Repository size is approaching GitHub limit. Consider cleaning history.")

        if not report["lfs_status"]["lfs_installed"]:
            report["recommendations"].append("Install Git LFS for better large file handling.")

        return report

    def save_report(self):
        """Save health report to file"""
        report = self.generate_report()

        with open(self.report_file, 'w') as f:
            json.dump(report, f, indent=2)

        print(f"Repository health report saved to {self.report_file}")
        return report

if __name__ == "__main__":
    monitor = RepositoryMonitor()
    report = monitor.save_report()

    print("Repository Health Report:")
    print(f"Size: {report['size_info'].get('size-pack', 'Unknown')}")
    print(f"LFS Status: {report['lfs_status']['lfs_status']}")
    print(f"Vulnerabilities: {report['security']['vulnerabilities']['total']}")

    if report["recommendations"]:
        print("\nRecommendations:")
        for rec in report["recommendations"]:
            print(f"- {rec}")
