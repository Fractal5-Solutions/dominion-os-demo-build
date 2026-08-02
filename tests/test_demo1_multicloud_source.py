import json
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PAGE = ROOT / "squarespace" / "demo-1-final.html"
CLOUD_MANIFEST = ROOT / "demo" / "assets" / "cloud-deployment-manifest.json"
DEMO_MANIFEST = ROOT / "demo" / "assets" / "demo-manifest.json"
RUNTIME_MANIFEST = ROOT / "demo" / "assets" / "multicloud-runtime-manifest.json"
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
        provider = attrs.get("data-provider") or attrs.get("data-provider-id")
        if provider:
            self.provider_ids.append(provider)
        if tag == "a":
            self.anchors.append(attrs)


def load_page():
    text = PAGE.read_text(encoding="utf-8")
    parser = DemoPageParser()
    parser.feed(text)
    parser.close()
    return text, parser


def test_demo1_page_asserts_evidence_driven_multicloud_contract():
    text, parser = load_page()

    assert 'data-version="2026-08-02-multicloud-proof-v2"' in text
    assert "One governed system. Your cloud." in text
    assert "Independent estates. One release contract." in text
    assert "Deployment-ready. Runtime claims fail closed." in text
    assert Counter(parser.provider_ids) == Counter(
        {"gcp": 1, "azure": 1, "aws": 1, "oci": 1}
    )
    assert len(parser.ids) == len(set(parser.ids))
    assert "LIVE GOOGLE CLOUD DEMO" not in text
    assert "continuous public runtime" not in text.lower()
    assert "marketplace availability" not in text.lower()


def test_primary_demo_defaults_to_verified_static_proof():
    _, parser = load_page()
    primary = next(anchor for anchor in parser.anchors if anchor.get("id") == "f5-primary-demo")

    assert primary["href"] == "https://fractal5-solutions.github.io/dominion-os-demo-build/"
    assert primary.get("target") == "_blank"
    assert "noopener" in primary.get("rel", "")
    assert "noreferrer" in primary.get("rel", "")


def test_runtime_promotion_is_fail_closed_and_allowlisted():
    text, _ = load_page()

    assert '"publicClaimAllowed":false' not in text
    assert "provider.publicClaimAllowed!==true" in text
    assert "approvedHttps(provider.healthUrl,\"/health\")" in text
    assert "approvedHttps(provider.demoUrl,\"/demo\")" in text
    assert 'Date.now()-stamp>300000' in text
    assert 'setPill("is-live","Google Cloud live")' in text


def test_all_static_links_use_safe_public_routes():
    _, parser = load_page()
    for anchor in parser.anchors:
        href = anchor.get("href", "")
        assert href.startswith("https://") or href.startswith("#")
        if anchor.get("target") == "_blank":
            assert "noopener" in anchor.get("rel", "")
            assert "noreferrer" in anchor.get("rel", "")


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
    runtime = json.loads(RUNTIME_MANIFEST.read_text(encoding="utf-8"))
    receipts = json.loads(RECEIPTS.read_text(encoding="utf-8"))

    assert demo["assets"]["cloudDeployments"].endswith(
        "/cloud-deployment-manifest.json"
    )
    assert demo["deploymentReadiness"]["state"] == "ready"
    assert demo["deploymentReadiness"]["publicRuntimeDependency"] is False
    assert demo["publicDemo"]["state"] == "verified"
    assert demo["publicDemo"]["providerRuntimeDependency"] is False
    assert demo["optionalReferenceRuntime"]["state"] == "uncertified"
    assert demo["optionalReferenceRuntime"]["publicClaimAllowed"] is False
    assert demo["claimControl"]["deploymentReady"] is True
    assert demo["claimControl"]["fourProviderDeploymentReadinessAllowed"] is True
    assert demo["claimControl"]["rawCloudRunDemoPublicGreen"] is False
    assert demo["claimControl"]["continuousPublicReferenceRuntimeRequired"] is False

    providers = {provider["id"]: provider for provider in runtime["providers"]}
    assert providers["gcp"]["publicRuntimeState"] == "uncertified"
    assert all(provider["publicClaimAllowed"] is False for provider in providers.values())
    assert runtime["staticProof"]["publicClaimAllowed"] is True

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
