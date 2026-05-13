"""
prolog_bridge.py

Thin wrapper around pyswip that exposes the game-relevant predicates as Python
functions. Because pyswip embeds a single SWI-Prolog engine per process we use
a global engine and a coarse threading lock; the game state lives entirely in
Prolog's dynamic predicates (`known/2`, `revealed_clue/2`, `mistake/1`,
`hinted/1`).

Multiple concurrent sessions are supported by namespacing the dynamic facts
behind a per-session id; we model this in Python by serializing access and
calling `state:reset_state/0` whenever switching sessions.
"""

from __future__ import annotations

import os
import threading
from dataclasses import dataclass
from typing import Any, Dict, Iterable, List, Optional

from pyswip import Prolog

PROLOG_DIR = os.path.join(os.path.dirname(__file__), "prolog")
PUZZLE_DIR = os.path.join(PROLOG_DIR, "puzzles")

_LOCK = threading.RLock()


def _strip(token: Any) -> Any:
    """Recursively decode pyswip Atom/Functor objects into plain Python."""
    name = type(token).__name__
    if name == "Atom":
        return token.value if hasattr(token, "value") else str(token)
    if name == "Functor":
        # Functor objects expose .name (Atom) and .args (list)
        args = [_strip(a) for a in getattr(token, "args", [])]
        fname = getattr(token, "name", None)
        if hasattr(fname, "value"):
            fname = fname.value
        return {"functor": str(fname), "args": args}
    if isinstance(token, bytes):
        return token.decode("utf-8")
    if isinstance(token, list):
        return [_strip(t) for t in token]
    if isinstance(token, dict):
        return {k: _strip(v) for k, v in token.items()}
    return token


@dataclass
class CharacterInfo:
    cell: str
    name: str
    role: str
    group: str

    def to_dict(self) -> Dict[str, Any]:
        return self.__dict__.copy()


class PrologEngine:
    """Singleton-ish wrapper that owns the global Prolog engine."""

    _instance: Optional["PrologEngine"] = None

    def __init__(self) -> None:
        self.prolog = Prolog()
        self._loaded_core = False
        self._current_puzzle: Optional[str] = None
        self._sessions: Dict[str, Dict[str, Optional[str]]] = {}
        self._last_session_id: str = "default"
        self.load_core()

    @classmethod
    def get(cls) -> "PrologEngine":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def load_core(self) -> None:
        if self._loaded_core:
            return
        for fname in [
            "puzzle_facts.pl",
            "board.pl",
            "graph.pl",
            "trees.pl",
            "evidence.pl",
            "state.pl",
            "clues.pl",
            "solver.pl",
            "verifier.pl",
            "generator.pl",
        ]:
            path = os.path.join(PROLOG_DIR, fname).replace("\\", "/")
            list(self.prolog.query(f"consult('{path}')"))
        self._loaded_core = True

    # ------------------------------------------------------------------
    # Puzzle management
    # ------------------------------------------------------------------
    def list_puzzles(self) -> List[Dict[str, str]]:
        out = []
        for fname in sorted(os.listdir(PUZZLE_DIR)):
            if fname.endswith(".pl"):
                pid = fname[:-3]
                out.append({"id": pid, "filename": fname})
        return out

    def load_puzzle(self, puzzle_id: str) -> None:
        with _LOCK:
            path = os.path.join(PUZZLE_DIR, f"{puzzle_id}.pl").replace("\\", "/")
            if not os.path.exists(path):
                raise FileNotFoundError(f"unknown puzzle: {puzzle_id}")
            list(self.prolog.query("retractall(user:character(_,_,_,_))"))
            list(self.prolog.query("retractall(user:revealed_at_start(_))"))
            list(self.prolog.query("retractall(user:clue_of(_,_))"))
            list(self.prolog.query("retractall(user:solution(_,_))"))
            list(self.prolog.query("retractall(user:puzzle_title(_))"))
            list(self.prolog.query("retractall(user:puzzle_difficulty(_))"))
            list(self.prolog.query(f"consult('{path}')"))
            self._current_puzzle = puzzle_id

    def _resolve_session_id(self, session_id: Optional[str]) -> str:
        if session_id:
            return session_id
        if self._last_session_id:
            return self._last_session_id
        return "default"

    def _prepare_session(
        self,
        session_id: Optional[str],
        require_puzzle: bool = False,
    ) -> str:
        sid = self._resolve_session_id(session_id)
        self._sessions.setdefault(sid, {"puzzle_id": None})
        self._last_session_id = sid
        list(self.prolog.query(f"state:set_session({_quote_atom(sid)})"))
        puzzle_id = self._sessions[sid]["puzzle_id"]
        if require_puzzle and puzzle_id is None:
            raise RuntimeError("session has no active puzzle")
        if puzzle_id and puzzle_id != self._current_puzzle:
            self.load_puzzle(puzzle_id)
            list(self.prolog.query(f"state:set_session({_quote_atom(sid)})"))
        return sid

    # ------------------------------------------------------------------
    # Game queries
    # ------------------------------------------------------------------
    def get_characters(self) -> List[CharacterInfo]:
        results = list(self.prolog.query("user:character(C, N, R, G)"))
        chars: List[CharacterInfo] = []
        for r in results:
            chars.append(
                CharacterInfo(
                    cell=str(r["C"]),
                    name=_to_text(r["N"]),
                    role=str(r["R"]),
                    group=str(r["G"]),
                )
            )
        return chars

    def revealed_at_start(self) -> str:
        results = list(self.prolog.query("user:revealed_at_start(C)"))
        if not results:
            raise RuntimeError("puzzle does not declare revealed_at_start/1")
        return str(results[0]["C"])

    def clue_text(self, cell: str) -> Optional[str]:
        results = list(self.prolog.query(
            f"user:clue_of({cell}, C), clues:describe_clue_for({cell}, C, T)"))
        if not results:
            return None
        return _to_text(results[0]["T"])

    def known_cells(self, session_id: Optional[str] = None) -> List[Dict[str, str]]:
        self._prepare_session(session_id, require_puzzle=True)
        results = list(self.prolog.query("state:known(C, S)"))
        return [{"cell": str(r["C"]), "status": str(r["S"])} for r in results]

    def revealed_clues(self, session_id: Optional[str] = None) -> List[Dict[str, str]]:
        self._prepare_session(session_id, require_puzzle=True)
        results = list(self.prolog.query(
            "state:revealed_clue(C, Cl), clues:describe_clue_for(C, Cl, T)"))
        out = []
        for r in results:
            try:
                term = _term_to_atom(self.prolog, r["Cl"])
            except Exception:
                term = str(r["Cl"])
            out.append({
                "cell": str(r["C"]),
                "text": _to_text(r["T"]),
                "term": term,
            })
        return out

    def mistakes(self, session_id: Optional[str] = None) -> List[Dict[str, str]]:
        self._prepare_session(session_id, require_puzzle=True)
        results = list(self.prolog.query("state:mistake(C-S)"))
        out = []
        for r in results:
            m = r["C"]
            # pyswip sometimes returns Functor for "-" terms
            if hasattr(m, "args"):
                cell = str(m.args[0])
                status = str(m.args[1])
            else:
                cell = str(r.get("C"))
                status = str(r.get("S"))
            out.append({"cell": cell, "status": status})
        return out

    def hinted(self, session_id: Optional[str] = None) -> List[str]:
        self._prepare_session(session_id, require_puzzle=True)
        results = list(self.prolog.query("state:hinted(C)"))
        return [str(r["C"]) for r in results]

    def solution(self, session_id: Optional[str] = None) -> Dict[str, str]:
        self._prepare_session(session_id, require_puzzle=True)
        results = list(self.prolog.query("user:solution(C, S)"))
        return {str(r["C"]): str(r["S"]) for r in results}

    # ------------------------------------------------------------------
    # Game actions
    # ------------------------------------------------------------------
    def start_game(self, puzzle_id: str, session_id: Optional[str] = None) -> Dict[str, Any]:
        with _LOCK:
            sid = self._prepare_session(session_id)
            self.load_puzzle(puzzle_id)
            self._sessions[sid]["puzzle_id"] = puzzle_id
            list(self.prolog.query(f"state:set_session({_quote_atom(sid)})"))
            list(self.prolog.query("state:reset_state"))
            start = self.revealed_at_start()
            results = list(self.prolog.query(f"user:solution({start}, S)"))
            status = str(results[0]["S"]) if results else "unknown"
            list(self.prolog.query(f"state:register_known({start}, {status})"))
            list(self.prolog.query(f"state:reveal_clue_for({start})"))
            return self.snapshot(sid)

    def make_choice(
        self,
        cell: str,
        status: str,
        session_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        with _LOCK:
            sid = self._prepare_session(session_id, require_puzzle=True)
            results = list(self.prolog.query(
                f"solver:forced({cell}, S)"))
            if not results:
                # Not forced at all — record as mistake.
                list(self.prolog.query(
                    f"state:record_mistake({cell}, {status})"))
                return {
                    "ok": False,
                    "reason": "not_enough_evidence",
                    "snapshot": self.snapshot(sid),
                }
            forced_status = str(results[0]["S"])
            if forced_status != status:
                # Forced to the OTHER status; user picked wrong.
                list(self.prolog.query(
                    f"state:record_mistake({cell}, {status})"))
                return {
                    "ok": False,
                    "reason": "wrong_status",
                    "actual_status": forced_status,
                    "snapshot": self.snapshot(sid),
                }
            # Correct & forced.
            list(self.prolog.query(
                f"state:register_known({cell}, {status})"))
            list(self.prolog.query(f"state:reveal_clue_for({cell})"))
            new_clue: Optional[Dict[str, Any]] = None
            desc = list(self.prolog.query(
                f"user:clue_of({cell}, Cl), clues:describe_clue_for({cell}, Cl, T)"))
            if desc:
                new_clue = {
                    "cell": cell,
                    "text": _to_text(desc[0]["T"]),
                }
            return {
                "ok": True,
                "revealed_clue": new_clue,
                "snapshot": self.snapshot(sid),
            }

    def forced_cells(self, session_id: Optional[str] = None) -> List[Dict[str, str]]:
        """Iterate every unknown character and check if `forced/2` succeeds.
        We can't call `solver:forced(C,S)` with C unbound because the
        negation-as-failure inside the solver short-circuits when C is a
        free variable.
        """
        self._prepare_session(session_id, require_puzzle=True)
        out: List[Dict[str, str]] = []
        known = {k["cell"] for k in self.known_cells(session_id)}
        for ch in self.get_characters():
            cell = ch.cell
            if cell in known:
                continue
            res = list(self.prolog.query(f"solver:forced({cell}, S)"))
            if res:
                out.append({"cell": cell, "status": str(res[0]["S"])})
        return out

    def hint(self, level: int, session_id: Optional[str] = None) -> Dict[str, Any]:
        """level 1: highlight clues that contribute to a forcing now;
        level 2: highlight cells that ARE forced right now and mark them as
        hint-revealed in the end-game stats."""
        with _LOCK:
            sid = self._prepare_session(session_id, require_puzzle=True)
            if level == 1:
                clues = self.revealed_clues(sid)
                # Heuristic: every revealed clue is potentially "active" —
                # a smarter engine could test each one for necessity.
                return {"highlighted_clues": clues, "snapshot": self.snapshot(sid)}
            if level == 2:
                forced = self.forced_cells(sid)
                cells = [f["cell"] for f in forced]
                for c in cells:
                    list(self.prolog.query(f"state:register_hinted({c})"))
                return {"highlighted_cells": cells, "snapshot": self.snapshot(sid)}
            raise ValueError("level must be 1 or 2")

    def reset(self, session_id: Optional[str] = None) -> Dict[str, Any]:
        with _LOCK:
            sid = self._prepare_session(session_id)
            puzzle_id = self._sessions[sid]["puzzle_id"]
            list(self.prolog.query("state:reset_state"))
            if puzzle_id is not None:
                self.start_game(puzzle_id, sid)
            return self.snapshot(sid)

    # ------------------------------------------------------------------
    # Snapshot
    # ------------------------------------------------------------------
    def snapshot(self, session_id: Optional[str] = None) -> Dict[str, Any]:
        sid = self._prepare_session(session_id, require_puzzle=True)
        chars = [c.to_dict() for c in self.get_characters()]
        title = self._query_first("user:puzzle_title(T)", "T")
        difficulty = self._query_first("user:puzzle_difficulty(D)", "D")
        puzzle_id = self._sessions[sid]["puzzle_id"]
        return {
            "puzzle_id": puzzle_id,
            "title": _to_text(title) if title else None,
            "difficulty": str(difficulty) if difficulty else None,
            "characters": chars,
            "known": self.known_cells(sid),
            "revealed_clues": self.revealed_clues(sid),
            "mistakes": self.mistakes(sid),
            "hinted": self.hinted(sid),
            "won": self._is_won(),
        }

    def _is_won(self) -> bool:
        results = list(self.prolog.query("state:known_count(N)"))
        return bool(results) and int(results[0]["N"]) == 20

    def _query_first(self, q: str, var: str) -> Any:
        results = list(self.prolog.query(q))
        if not results:
            return None
        return results[0][var]


# ----------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------

def _to_text(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    if isinstance(value, list):
        # pyswip strings sometimes come as a list of char codes.
        try:
            return bytes(int(c) for c in value).decode("utf-8", errors="replace")
        except (TypeError, ValueError):
            return str(value)
    return str(value)


def _term_to_atom(prolog: Prolog, term: Any) -> str:
    """Render a Python pyswip term back into a Prolog source string."""
    name = type(term).__name__
    if name == "Atom":
        return str(term)
    if name == "Functor":
        fname = getattr(term, "name", None)
        if hasattr(fname, "value"):
            fname = fname.value
        args = [_term_to_atom(prolog, a) for a in getattr(term, "args", [])]
        return f"{fname}({', '.join(args)})"
    if isinstance(term, str):
        # pyswip>=0.3 already serializes compound terms back to a textual
        # Prolog form. Atoms without weird chars are returned unquoted, so we
        # only need to quote *plain* atoms that contain whitespace/punctuation.
        if "(" in term or "[" in term or "," in term:
            return term
        return _quote_atom(term)
    if isinstance(term, bytes):
        return _quote_atom(term.decode("utf-8"))
    if isinstance(term, list):
        return "[" + ", ".join(_term_to_atom(prolog, x) for x in term) + "]"
    if isinstance(term, (int, float)):
        return str(term)
    # Fallback: ask Prolog to render the term as an atom.
    results = list(prolog.query(f"with_output_to(string(S), write_canonical({term}))"))
    if results:
        return _to_text(results[0]["S"])
    return str(term)


_NEEDS_QUOTE = set(" \t\n\"'(),[]{}!|.")


def _quote_atom(atom: str) -> str:
    if atom and atom[0].islower() and all(
        ch.isalnum() or ch == "_" for ch in atom
    ):
        return atom
    escaped = atom.replace("\\", "\\\\").replace("'", "\\'")
    return f"'{escaped}'"
