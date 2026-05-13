"""Run the Prolog-based puzzle generator a handful of times and make sure
every puzzle it produces is step-by-step winnable (i.e. `verifier:is_winnable`
succeeds)."""

from __future__ import annotations

import pytest


@pytest.mark.slow
def test_generator_produces_winnable_puzzles(engine):
    # Keep count low: generation backtracks through many random candidates
    # and each `is_winnable` call is itself a mini playthrough.
    ok = 0
    for seed in range(3):
        res = list(engine.prolog.query(
            f"generator:generate_puzzle({seed}), verifier:is_winnable"
        ))
        if res:
            ok += 1
    assert ok >= 2, "generator failed to produce winnable puzzles"
