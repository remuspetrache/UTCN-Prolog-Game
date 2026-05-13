"""Attempt a choice that matches the final solution but is not yet *forced*.

This protects the teaching invariant: the game may only accept a status for a
cell when the accumulated evidence uniquely determines it. Even if the
player happens to guess correctly, an unforced answer must be recorded as a
mistake.
"""

from __future__ import annotations


def test_unforced_correct_guess_is_rejected(client, engine):
    r = client.post("/api/game/new", json={"puzzle_id": "puzzle_01"})
    assert r.status_code == 200

    solution = client.get("/api/game/solution").json()["solution"]
    # Pick a cell that is in the solution but NOT yet forced after only the
    # initial clue. For puzzle_01 (row 1 has 0 restantieri) the row-2 cells
    # aren't forced until the next clue is revealed via a1.
    snap = client.get("/api/game/state").json()
    forced_now = {f["cell"] for f in engine.forced_cells()}
    known_now = {k["cell"] for k in snap["known"]}
    target = next(
        cell for cell, status in solution.items()
        if cell not in forced_now and cell not in known_now
    )
    target_status = solution[target]

    res = client.post(
        "/api/game/choose", json={"cell": target, "status": target_status}
    ).json()
    assert res["ok"] is False
    assert res["reason"] == "not_enough_evidence"
    assert any(m["cell"] == target for m in res["snapshot"]["mistakes"])


def test_wrong_status_reported(client, engine):
    client.post("/api/game/new", json={"puzzle_id": "puzzle_01"})
    # Pick a cell that *is* already forced from the starting clue and ask for
    # the opposite of its forced status — the engine must report "wrong_status".
    forced = engine.forced_cells()
    assert forced, "expected at least one cell to be forced after the start"
    cell = forced[0]["cell"]
    actual = forced[0]["status"]
    opposite = "restantier" if actual == "integralist" else "integralist"
    res = client.post(
        "/api/game/choose", json={"cell": cell, "status": opposite}
    ).json()
    assert res["ok"] is False
    assert res["reason"] == "wrong_status"
    assert res["actual_status"] == actual
