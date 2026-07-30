import json
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PAGE = ROOT / "squarespace" / "demo-1-final.html"
CLOUD_MANIFEST = ROOT / "demo" / "assets" / "cloud-deployment-manifest.json"
DEMO_MANIFEST = ROOT / "demo" / "assets" / "demo-manifest.json"
RECEIPTS = ROOT / "demo" / "assets" / "release-receipts.json"


class DemoPageParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.ids = []
        self.provider_ids = []
        self.anchors = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if "id" in attrs:
            self.ids.append(attrs["id"])
        if "data-provider-id" in attrs:
            self.provider_ids.append(attrs["data-provider-id"])
        if tag == "a":
            self.anchors.append(attrs)


def load_page():
    text = PAGE.read_text(encoding="utf-8")
    parser = DemoPageParser()
    parser.feed(text)
    parser.close()
    return text, parser


def test_demo1_page_asserts_canonical_multicloud_readiness():
    text, parser = load_page()

    assert 'data-version="2026-07-30-multicloud-ready"' in text
    assert "Dominion OS is ready for your cloud." in text
    assert "Ready across four clouds. Governed as one system." in text
    assert Counter(parser.provider_ids) == Counter({
        "gcp": 1,
        "azure": 1,
        "aws": 1,
        "oci": 1,
    })
    assert len(parser.ids) == len(set(parser.ids))
    assert "LIVE GOOGLE CLOUD DEMO" not in text
    assert "verification pending" not in text.lower()
    assert "not presently verified" not in text.lower()
    assert "payment systems, operational keys, payment systems" not in text
    assert "marketplace" not in text.lower()


def test_runtime_actions_are_additive_and_fail_safe():
    _, parser = load_page()
    runtime_actions = [a for a in parser.anchors if a.get("data-runtime-target")]

    assert runtime_actions
    for anchor in runtime_actions:
        assert anchor["data-runtime-target"].startswith(
            "https://demo-reduwyf2ra-uc.a.run.app/"
        )
        target = anchor["data-runtime-target"]
        href = anchor["href"]
        if target.endswith("/demo"):
            assert href == "#deployment-platforms"
        elif target.endswith("/health"):
            assert href == "https://www.fractal5solutions.com/dominion-os"
        else:
            raise AssertionError(f"Unexpected runtime target: {target}")
        assert href != target
        if anchor.get("target") == "_blank":
            assert "noopener" in anchor.get("rel", "")


def test_all_static_links_use_safe_public_routes():
    _, parser = load_page()
    for anchor in parser.anchors:
        href = anchor.get("href", "")
        assert href.startswith("https://") or href.startswith("#")


def test_cloud_manifest_asserts_four_provider_deployment_readiness():
    manifest = json.loads(CLOUD_MANIFEST.read_text(encoding="utf-8"))
    providers = {provider["id"]: provider for provider in manifest["providers"]}

    assert set(providers) == {"gcp", "azure", "aws", "oci"}
    assert {provider["state"] for provider in providers.values()} == {
        "deployment-ready"
    }
    assert {provider["publicLabel"] for provider in providers.values()} == {
        "Deployment ready"
    }
    assert providers["oci"]["evidence"]["dedicatedProviderRepository"] is None

    claims = manifest["claimControl"]
    assert claims["mayClaimMultiCloudDeploymentArchitecture"] is True
    assert claims["mayClaimFourProviderDeploymentReadiness"] is True
    assert claims["mayClaimGoogleCloudPublicRuntimeLive"] is False
    assert claims["mayClaimFourContinuouslyLivePublicDeployments"] is False
    assert claims["mayClaimMarketplaceAvailabilityAcrossAllProviders"] is False
    assert manifest["deploymentReadiness"]["state"] == "ready"
    assert manifest["deploymentReadiness"]["publicRuntimeDependency"] is False
    assert manifest["safety"]["publicSafe"] is True


def test_demo_manifest_and_receipts_separate_readiness_from_demo_uptime():
    demo = json.loads(DEMO_MANIFEST.read_text(encoding="utf-8"))
    receipts = json.loads(RECEIPTS.read_text(encoding="utf-8"))

    assert demo["assets"]["cloudDeployments"].endswith(
        "/cloud-deployment-manifest.json"
    )
    assert demo["deploymentReadiness"]["state"] == "ready"
    assert demo["deploymentReadiness"]["publicRuntimeDependency"] is False
    assert demo["claimControl"]["deploymentReady"] is True
    assert demo["claimControl"]["fourProviderDeploymentReadinessAllowed"] is True
    assert demo["claimControl"]["rawCloudRunDemoPublicGreen"] is False
    assert demo["claimControl"]["continuousPublicReferenceRuntimeRequired"] is False

    review = receipts["currentReview"]
    assert review["state"] == "deployment-ready"
    assert review["publicReferenceRuntime"]["liveClaimAllowed"] is False
    assert {
        route["observedHttpStatus"]
        for route in review["publicReferenceRuntime"]["routes"]
    } == {404}
    assert receipts["deploymentReadiness"]["state"] == "ready"
    assert receipts["claimControl"]["fourProviderDeploymentReadinessAllowed"] is True
    assert receipts["safety"]["publicSafe"] is True
