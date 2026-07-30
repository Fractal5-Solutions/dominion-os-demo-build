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


def test_receipt_allows_fractal5_page_origin():
    with app.test_client() as client:
        response = client.get(
            "/health",
            headers={"Origin": "https://www.fractal5solutions.com"},
        )
    assert response.headers["Access-Control-Allow-Origin"] == "https://www.fractal5solutions.com"
    assert "Origin" in response.headers.get("Vary", "")


def test_receipt_allows_apex_fractal5_origin():
    with app.test_client() as client:
        response = client.get(
            "/status",
            headers={"Origin": "https://fractal5solutions.com"},
        )
    assert response.headers["Access-Control-Allow-Origin"] == "https://fractal5solutions.com"


def test_receipt_rejects_untrusted_origin():
    with app.test_client() as client:
        response = client.get(
            "/health",
            headers={"Origin": "https://example.com"},
        )
    assert "Access-Control-Allow-Origin" not in response.headers
