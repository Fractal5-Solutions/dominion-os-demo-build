import json
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PAGE = ROOT / "squarespace" / "demo-1-final.html"
CLOUD_MANIFEST = ROOT / "demo" / "assets" / "cloud-deployment-manifest.json"
DEMO_MANIFEST = ROOT / "demo" / "assets" / "demo-manifest.json"
RUNTIME_MANIFEST = ROOT / "demo" / "assets" / "multicloud-runtime-manifest.json"
PACKAGE = ROOT / "demo" / "assets" / "demo-download-package.json"
RECEIPTS = ROOT / "demo" / "assets" / "release-receipts.json"
RUNTIME_WRAPPER = ROOT / "commercial_runtime.py"


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
    assert "Four continuously live public deployments" not in text
    assert "marketplace availability" not in text.lower()


def test_primary_demo_defaults_to_public_static_proof():
    text, parser = load_page()
    primary = next(anchor for anchor in parser.anchors if anchor.get("id") == "f5-primary-demo")

    assert primary["href"] == "https://fractal5-solutions.github.io/dominion-os-demo-build/"
    assert primary.get("target") == "_blank"
    assert "noopener" in primary.get("rel", "")
    assert "noreferrer" in primary.get("rel", "")
    assert "Open public static demo" in text
    assert "Static proof available" in text


def test_runtime_promotion_is_fail_closed_release_bound_and_revision_bound():
    text, _ = load_page()

    assert "provider.publicClaimAllowed!==true" in text
    assert "approvedHttps(provider.healthUrl,\"/health\")" in text
    assert "approvedHttps(provider.demoUrl,\"/demo\")" in text
    assert "expectedReleaseSha" in text
    assert "releaseCandidateSha" in text
    assert "revision" in text
    assert 'Date.now()-stamp>300000' in text
    assert 'setPill("is-live","Google Cloud live")' in text


def test_static_verification_depends_on_deployed_release_receipt():
    text, _ = load_page()

    assert "staticReceipt" in text
    assert "receipt.pass===true" in text
    assert "receipt.failClosed===true" in text
    assert "receipt.providerRuntimeClaimedLive===false" in text
    assert "releaseSha" in text


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
    assert {provider["state"] for provider in providers.values()} == {"deployment-ready"}
    assert {provider["publicLabel"] for provider in providers.values()} == {"Deployment ready"}
    assert providers["oci"]["evidence"]["dedicatedProviderRepository"] is None

    claims = manifest["claimControl"]
    assert claims["mayClaimMultiCloudDeploymentArchitecture"] is True
    assert claims["mayClaimFourProviderDeploymentReadiness"] is True
    assert claims["mayClaimGoogleCloudPublicRuntimeLive"] is False
    assert claims["mayClaimFourContinuouslyLivePublicDeployments"] is False
    assert claims["mayClaimMarketplaceAvailabilityAcrossAllProviders"] is False
    assert manifest["deploymentReadiness"]["state"] == "ready"
    assert manifest["safety"]["publicSafe"] is True


def test_runtime_manifest_source_does_not_self_certify():
    runtime = json.loads(RUNTIME_MANIFEST.read_text(encoding="utf-8"))
    providers = {provider["id"]: provider for provider in runtime["providers"]}

    assert runtime["staticProof"]["state"] == "source-ready"
    assert runtime["staticProof"]["publicClaimAllowed"] is False
    assert providers["gcp"]["publicRuntimeState"] == "uncertified"
    assert all(provider["publicClaimAllowed"] is False for provider in providers.values())
    cert = providers["gcp"]["certification"]
    assert cert["requiredReleaseBinding"] is True
    assert cert["requiredNamedRevision"] is True
    assert cert["expectedReleaseSha"] is None


def test_public_package_contains_no_runtime_or_mp4_claims():
    package = json.loads(PACKAGE.read_text(encoding="utf-8"))
    assert package["runtimeDemo"] is None
    assert package["claimControl"]["directMp4Included"] is False
    assert package["claimControl"]["runtimeRouteIncluded"] is False
    assert package["claimControl"]["providerRuntimeClaimedLive"] is False
    urls = [item["url"] for item in package["contents"]]
    assert not any(url.lower().endswith(".mp4") for url in urls)
    assert not any("demo-reduwyf2ra-uc.a.run.app" in url for url in urls)


def test_pages_origin_is_allowed_for_public_runtime_receipts():
    text = RUNTIME_WRAPPER.read_text(encoding="utf-8")
    assert '"https://fractal5-solutions.github.io"' in text


def test_demo_manifest_and_receipts_keep_runtime_claims_fail_closed():
    demo = json.loads(DEMO_MANIFEST.read_text(encoding="utf-8"))
    receipts = json.loads(RECEIPTS.read_text(encoding="utf-8"))

    assert demo["assets"]["cloudDeployments"].endswith("/cloud-deployment-manifest.json")
    assert demo["deploymentReadiness"]["state"] == "ready"
    assert demo["publicDemo"]["providerRuntimeDependency"] is False
    assert demo["optionalReferenceRuntime"]["publicClaimAllowed"] is False
    assert demo["claimControl"]["deploymentReady"] is True
    assert demo["claimControl"]["fourProviderDeploymentReadinessAllowed"] is True
    assert demo["claimControl"]["rawCloudRunDemoPublicGreen"] is False
    assert demo["claimControl"]["continuousPublicReferenceRuntimeRequired"] is False

    review = receipts["currentReview"]
    assert review["state"] == "deployment-ready"
    assert review["publicReferenceRuntime"]["liveClaimAllowed"] is False
    assert receipts["deploymentReadiness"]["state"] == "ready"
    assert receipts["claimControl"]["fourProviderDeploymentReadinessAllowed"] is True
    assert receipts["safety"]["publicSafe"] is True
