# UTCN Clues — Student Repository

## What is this?

UTCN Clues is a logic deduction game inspired by [Clues by Sam](https://cluesbysam.com/). You are given a 4×5 grid of cells, each of which is either an **integralist** or a **restantier**. At the start of a round a character reveals a clue about the grid; your task is to deduce which cells are which using only logical inference - no guessing allowed.

Your job in this repository is to implement the Prolog predicates that make the game work: board geometry, university tree traversal, a difference-list evidence log, a neighbor graph, and the core forced-value inference engine.

---

## Play the demo first (before writing any code)

You can play a complete reference game **without** installing SWI-Prolog, Python, or Node. You only need [Docker](https://docs.docker.com/get-docker/).

```bash
docker compose -f demo/docker-compose.yml up
```

Open **http://localhost:5173** in your browser.

When you are done:

```bash
docker compose -f demo/docker-compose.yml down
```

---

## What you need to implement

All student work lives in `backend/prolog/`. The six files below map directly to laboratory sessions.

| Lab File | Lab(s) | Game Component | Depends On |
|---|---|---|---|
| `lab03_board.pl` | L03, L06 | Board geometry (cells, rows, columns, corners, edges) | nothing |
| `lab07_trees.pl` | L07 | University group tree traversal | nothing |
| `lab09_evidence.pl` | L09 | Difference-list clue history | nothing |
| `lab10_state.pl` | L10 | Standalone exercises (not wired into the game) | nothing |
| `lab11_12_graph.pl` | L11, L12 | Neighbor graph + BFS connectivity | `lab03_board.pl` |
| `lab04_08_solver.pl` | L04, L08 | Forced-value inference engine | `lab03_board.pl`, `lab11_12_graph.pl` |

Each file contains predicate stubs in the style of the laboratory exercises: a description comment, a `?-` example query with expected output, and a `fail.` body to replace.

---

## Recommended implementation order

1. **`lab03_board.pl`** — Start here. `cells_in_row/2`, `all_cells/1`, and friends are used by almost everything else. The graph module calls `all_cells/1` at load time.

2. **`lab07_trees.pl`** — Independent of the board; can be done in parallel with step 1 or immediately after. Needed for clues that mention specific groups (e.g., "group 311 has 2 integraliști").

3. **`lab09_evidence.pl`** — Independent. Practice the S-E difference-list representation before tackling the more complex predicates.

4. **`lab10_state.pl`** — Standalone exercises; complete them at any point to understand the `assertz`/`retractall`/`findall` patterns used in the provided `state.pl`.

5. **`lab11_12_graph.pl`** — Requires `lab03_board.pl` (step 1) to be complete first, because `build_neighbors/0` calls `all_cells/1` at load time. After completing this file, reload SWI-Prolog so the neighbor facts are populated.

6. **`lab04_08_solver.pl`** — Requires both step 1 and step 5. This is the final piece: once it is implemented, the full game becomes playable locally.

---

## Prerequisites for running the full game locally

- **SWI-Prolog** ≥ 9.0 — [https://www.swi-prolog.org/Download.html](https://www.swi-prolog.org/Download.html)
- **Python** ≥ 3.10

  ```bash
  cd backend
  pip install -r requirements.txt
  ```

- **Node.js** ≥ 18 + npm

  ```bash
  cd frontend
  npm install
  ```

---

## Running the full game (after implementing all predicates)

Open two terminals from the repository root.

**Terminal 1 — Python backend:**

```bash
cd backend
uvicorn app:app --reload --port 8002
```

**Terminal 2 — React frontend:**

```bash
cd frontend
npm run dev
```

Open **http://localhost:5173** in your browser.

---

## Running the tests

### Prolog unit tests (plunit)

Run from the `backend/` directory:

```bash
swipl -g "['prolog/tests.pl'], run_tests, halt(0)" -t "halt(1)"
```

Test clusters and the lab files they cover:

| Test cluster | Lab file |
|---|---|
| `board_tests` | `lab03_board.pl` |
| `trees_tests` | `lab07_trees.pl` |
| `evidence_tests` | `lab09_evidence.pl` |
| `graph_tests` | `lab11_12_graph.pl` |
| `state_tests` | (provided `state.pl` — no student work) |

All five clusters passing means your pure-Prolog layer is correct.

### Python integration tests (pytest)

Run from the `backend/` directory (requires SWI-Prolog in your PATH):

```bash
pytest
```

Key test files and what they verify:

| Test file | What it checks |
|---|---|
| `test_clue_primitives.py` | Individual clue types via `check_clue/2` |
| `test_generator.py` | Puzzle generator produces solvable puzzles |
| `test_hint.py` | Hint endpoint returns correct forced cells |
| `test_puzzle_01_playable.py` | Full play-through of puzzle 01 via `forced/2` |
| `test_puzzle_02_playable.py` | Full play-through of puzzle 02 |
| `test_wrong_choice_rejected.py` | A guess without evidence is rejected |

All tests passing = your implementation is correct and the full game works.

---
