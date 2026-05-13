"""Same playthrough as puzzle_01 but for the medium-difficulty puzzle."""

from __future__ import annotations


def test_puzzle_02_fully_solvable(client, engine):
    r = client.post("/api/game/new", json={"puzzle_id": "puzzle_02"})
    assert r.status_code == 200
    snap = r.json()
    assert len(snap["known"]) == 1

    steps = 0
    while True:
        snap = client.get("/api/game/state").json()
        if snap["won"]:
            break
        forced = engine.forced_cells()
        assert forced, f"solver stuck after {steps} steps"
        cell = forced[0]["cell"]
        status = forced[0]["status"]
        res = client.post(
            "/api/game/choose", json={"cell": cell, "status": status}
        ).json()
        assert res["ok"], res
        steps += 1
        assert steps < 40

    final = client.get("/api/game/state").json()
    assert final["won"] is True
    assert len(final["known"]) == 20
    assert final["mistakes"] == []
