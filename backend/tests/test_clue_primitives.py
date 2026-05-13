"""Unit-tests for the pure Prolog clue primitives.

Runs `check_clue/2` against a handcrafted world so each kind has a positive
and a negative case. This exercises list counting (L03), difference-list /
list accumulators (L09), the graph neighbor facts (L11), and BFS-based
row/column connectivity (L12).
"""

from __future__ import annotations


def _make_world(engine, status_map):
    parts = []
    for cell, status in status_map.items():
        parts.append(f"cell({cell}, {status})")
    return "[" + ", ".join(parts) + "]"


ALL_ROW1_INT = {f"{c}1": "integralist" for c in "abcd"}
ALL_ROW5_REST = {f"{c}5": "restantier" for c in "abcd"}
MIXED = {
    "a1": "integralist", "b1": "integralist", "c1": "integralist", "d1": "integralist",
    "a2": "restantier",  "b2": "restantier",  "c2": "restantier",  "d2": "restantier",
    "a3": "integralist", "b3": "integralist", "c3": "restantier",  "d3": "integralist",
    "a4": "integralist", "b4": "integralist", "c4": "integralist",  "d4": "integralist",
    "a5": "restantier",  "b5": "restantier",  "c5": "restantier",  "d5": "restantier",
}


def _check(engine, clue, world_map):
    world = _make_world(engine, world_map)
    res = list(engine.prolog.query(f"clues:check_clue({clue}, {world})"))
    return bool(res)


def test_count_row(engine):
    assert _check(engine, "count_row(1, integralist, 4)", MIXED)
    assert _check(engine, "count_row(3, restantier, 1)", MIXED)
    assert not _check(engine, "count_row(1, restantier, 1)", MIXED)


def test_count_col(engine):
    assert _check(engine, "count_col(a, restantier, 2)", MIXED)
    assert not _check(engine, "count_col(a, restantier, 3)", MIXED)


def test_parity_row(engine):
    assert _check(engine, "parity_row(1, integralist, par)", MIXED)
    assert _check(engine, "parity_row(3, restantier, impar)", MIXED)


def test_direct_neighbor(engine):
    # The cell above c3 is c2 which is restantier.
    assert _check(engine, "direct_neighbor(c3, sus, restantier)", MIXED)
    # The cell below c3 is c4 which is integralist, so "sus=integralist"
    # should not hold.
    assert not _check(engine, "direct_neighbor(c3, sus, integralist)", MIXED)


def test_neighbor_count(engine):
    # c3 has 8 neighbours: b2,c2,d2 (rest), b3,d3 (int), b4,c4,d4 (int)
    # -> 3 restantieri
    assert _check(engine, "neighbor_count(c3, restantier, 3)", MIXED)
    assert not _check(engine, "neighbor_count(c3, restantier, 4)", MIXED)


def test_all_connected_row(engine):
    # Row 2 is all-restantier so trivially connected.
    assert _check(engine, "all_connected_row(2, restantier)", MIXED)
    # Row 3 has a single restantier (c3) -> connected by one-cell component.
    assert _check(engine, "all_connected_row(3, restantier)", MIXED)
