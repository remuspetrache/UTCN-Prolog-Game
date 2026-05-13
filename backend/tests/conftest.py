"""Pytest fixtures for the backend tests.

Because pyswip allocates a single SWI-Prolog engine per process, we keep a
module-scoped engine and reset its dynamic state between tests via
`engine.reset()`.
"""

from __future__ import annotations

import os
import sys

import pytest
from fastapi.testclient import TestClient

# Add parent dir to path so `from app import app` works when running pytest
# from the repository root.
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if ROOT not in sys.path:
    sys.path.insert(0, ROOT)

from app import app  # noqa: E402
from prolog_bridge import PrologEngine  # noqa: E402


@pytest.fixture(scope="session")
def engine() -> PrologEngine:
    return PrologEngine.get()


@pytest.fixture()
def client(engine: PrologEngine) -> TestClient:  # noqa: ARG001
    return TestClient(app)
