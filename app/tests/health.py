from src.version import get_version_info


def test_root(client):
    resp = client.get("/")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    # should include version info
    v = get_version_info()
    for k in ("version", "commit", "env"):
        assert k in data
        assert isinstance(data[k], str)




def test_liveness_readiness(client):
    assert client.get("/healthz/live").status_code == 200
    assert client.get("/healthz/ready").status_code == 200