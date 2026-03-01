#!/usr/bin/env python3
import subprocess


def test_website(url):
    try:
        result = subprocess.run(
            [
                "curl",
                "-s",
                "--max-time",
                "10",
                "--user-agent",
                "PHI-BIMS-Monitor/1.0 (Company Data Validation)",
                url,
            ],
            capture_output=True,
            text=True,
            timeout=15,
        )

        if result.returncode == 0 and result.stdout:
            print(f"SUCCESS: {url} - Content length: {len(result.stdout)}")
            return True, result.stdout.lower()
        else:
            print(f"FAILED: {url} - Return code: {result.returncode}")
            return False, ""
    except Exception as e:
        print(f"ERROR: {url} - {str(e)}")
        return False, ""


if __name__ == "__main__":
    # Test Fractal5
    success1, content1 = test_website("https://www.fractal5solutions.com")
    if success1:
        # Check for business keywords
        business_terms = ["sovereign", "ai", "systems", "development"]
        matches = sum(1 for term in business_terms if term in content1)
        match_rate = matches / len(business_terms) * 100
        print(f"Fractal5 keyword match rate: {match_rate:.1f}%")

    # Test Blue Wave
    success2, content2 = test_website("https://www.bluewaveactiongroup.ca")
    if success2:
        # Check for business keywords
        business_terms = ["political", "technology", "campaign", "infrastructure"]
        matches = sum(1 for term in business_terms if term in content2)
        match_rate = matches / len(business_terms) * 100
        print(f"Blue Wave keyword match rate: {match_rate:.1f}%")
