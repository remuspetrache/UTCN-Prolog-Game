"""Verify the two-level hint cycle reports sensible data and marks cells as
hinted when level 2 is requested."""

from __future__ import annotations


def test_hint_level1_returns_clues(client):
    client.post("/api/game/new", json={"puzzle_id": "puzzle_01"})
    res = client.post("/api/game/hint", json={"level": 1}).json()
    assert "highlighted_clues" in res
    assert len(res["highlighted_clues"]) >= 1
    for c in res["highlighted_clues"]:
        assert "cell" in c and "text" in c


def test_hint_level2_marks_cells(client):
    client.post("/api/game/new", json={"puzzle_id": "puzzle_01"})
    res = client.post("/api/game/hint", json={"level": 2}).json()
    # a1 is forced after the starting clue, so it should be in the hint list.
    assert res["highlighted_cells"], res
    snap = client.get("/api/game/state").json()
    for c in res["highlighted_cells"]:
        assert c in snap["hinted"]
