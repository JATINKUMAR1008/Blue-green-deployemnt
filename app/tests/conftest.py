import os
import pytest
from fastapi.testclient import TestClient
from src.main import app


@pytest.fixture(autouse=True)
def _env():
    os.environ.setdefault("APP_VERSION", "test")
    os.environ.setdefault("GIT_SHA", "abcdef1")
    os.environ.setdefault("APP_ENV", "test")
    yield


@pytest.fixture
def client():
    return TestClient(app)