"""End-to-end playthrough of puzzle_01 via the REST API.

Plays the hand-crafted puzzle using only the solver's `forced/2` output,
verifying that the game can be completed with 0 mistakes and that every
move the API accepts is flagged `ok=True`.
"""

from __future__ import annotations


def test_puzzle_01_fully_solvable(client, engine):
    r = client.post("/api/game/new", json={"puzzle_id": "puzzle_01"})
    assert r.status_code == 200
    snap = r.json()
    assert snap["revealed_at_start"] is not None
    assert len(snap["known"]) == 1
    assert len(snap["revealed_clues"]) == 1

    steps = 0
    while True:
        snap = client.get("/api/game/state").json()
        if snap["won"]:
            break
        forced = engine.forced_cells()
        assert forced, f"solver got stuck after {steps} steps"
        cell = forced[0]["cell"]
        status = forced[0]["status"]
        res = client.post(
            "/api/game/choose", json={"cell": cell, "status": status}
        ).json()
        assert res["ok"], res
        steps += 1
        assert steps < 40, "playthrough loop too long"

    final = client.get("/api/game/state").json()
    assert final["won"] is True
    assert len(final["known"]) == 20
    assert final["mistakes"] == []
    # Expect 19 placed choices (1 initial reveal + 19).
    assert steps == 19
