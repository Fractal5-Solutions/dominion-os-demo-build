from datetime import datetime, timezone

from commercial_runtime import app


def assert_fresh_receipt(response):
    assert response.status_code == 200
    assert response.headers["Cache-Control"] == "no-store, max-age=0, must-revalidate"
    assert response.headers["Pragma"] == "no-cache"

    payload = response.get_json()
    assert payload["generatedAt"] == payload["timestamp"]
    generated = datetime.fromisoformat(payload["generatedAt"].replace("Z", "+00:00"))
    age = (datetime.now(timezone.utc) - generated).total_seconds()
    assert 0 <= age < 5
    assert payload["receiptFreshnessSeconds"] == 0
    assert "revision" in payload
    assert "releaseCandidateSha" in payload


def test_health_receipt_is_fresh_and_uncached(monkeypatch):
    monkeypatch.setenv("K_REVISION", "test-revision")
    monkeypatch.setenv("RELEASE_SHA", "abc123")
    with app.test_client() as client:
        response = client.get("/health")
    assert_fresh_receipt(response)
    payload = response.get_json()
    assert payload["revision"] == "test-revision"
    assert payload["releaseCandidateSha"] == "abc123"


def test_status_receipt_is_fresh_and_uncached(monkeypatch):
    monkeypatch.setenv("K_REVISION", "test-revision")
    with app.test_client() as client:
        response = client.get("/status")
    assert_fresh_receipt(response)
