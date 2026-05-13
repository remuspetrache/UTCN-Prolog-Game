"""
FastAPI server that exposes the Prolog-powered game to the frontend.

Because pyswip is a single-engine-per-process wrapper we serialize all
interactions through the PrologEngine singleton. All business logic lives in
Prolog; this file is mostly JSON <-> dict plumbing.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any, Dict, List, Optional
from uuid import uuid4

from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field

from prolog_bridge import PrologEngine

app = FastAPI(title="Clues la UPB", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


class NewGameReq(BaseModel):
    puzzle_id: Optional[str] = Field(default=None, description="Puzzle file name (without .pl). If omitted, the first puzzle is loaded.")


class ChooseReq(BaseModel):
    cell: str
    status: str


class HintReq(BaseModel):
    level: int = 1


def engine() -> PrologEngine:
    return PrologEngine.get()


SESSION_COOKIE = "utcn_session_id"


def session_id_for(request: Request, response: Response) -> str:
    sid = request.cookies.get(SESSION_COOKIE)
    if sid:
        return sid
    sid = uuid4().hex
    response.set_cookie(
        key=SESSION_COOKIE,
        value=sid,
        httponly=True,
        samesite="lax",
        max_age=60 * 60 * 24 * 14,
    )
    return sid


@app.get("/api/puzzles")
def list_puzzles(request: Request, response: Response) -> Dict[str, List[Dict[str, str]]]:
    session_id_for(request, response)
    return {"puzzles": engine().list_puzzles()}


@app.post("/api/game/new")
def new_game(req: NewGameReq, request: Request, response: Response) -> Dict[str, Any]:
    sid = session_id_for(request, response)
    puzzles = engine().list_puzzles()
    if not puzzles:
        raise HTTPException(status_code=500, detail="No puzzles available")
    pid = req.puzzle_id or puzzles[0]["id"]
    try:
        snapshot = engine().start_game(pid, sid)
    except FileNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    snapshot["revealed_at_start"] = engine().revealed_at_start()
    return snapshot


@app.post("/api/game/choose")
def choose(req: ChooseReq, request: Request, response: Response) -> Dict[str, Any]:
    sid = session_id_for(request, response)
    if req.status not in ("integralist", "restantier"):
        raise HTTPException(
            status_code=400,
            detail="status must be 'integralist' or 'restantier'",
        )
    result = engine().make_choice(req.cell, req.status, sid)
    return result


@app.post("/api/game/hint")
def hint(req: HintReq, request: Request, response: Response) -> Dict[str, Any]:
    sid = session_id_for(request, response)
    if req.level not in (1, 2):
        raise HTTPException(status_code=400, detail="level must be 1 or 2")
    return engine().hint(req.level, sid)


@app.post("/api/game/reset")
def reset(request: Request, response: Response) -> Dict[str, Any]:
    sid = session_id_for(request, response)
    return engine().reset(sid)


@app.get("/api/game/state")
def state(request: Request, response: Response) -> Dict[str, Any]:
    sid = session_id_for(request, response)
    try:
        snap = engine().snapshot(sid)
    except RuntimeError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    try:
        snap["revealed_at_start"] = engine().revealed_at_start()
    except RuntimeError:
        snap["revealed_at_start"] = None
    return snap


@app.get("/api/game/solution")
def solution(request: Request, response: Response) -> Dict[str, Any]:
    """Exposed for testing + end-game popup. The frontend only reads this once
    the player has won."""
    sid = session_id_for(request, response)
    return {"solution": engine().solution(sid)}


@app.get("/healthz")
def healthz() -> Dict[str, str]:
    return {"status": "ok"}


BACKEND_DIR = Path(__file__).resolve().parent
FRONTEND_DIST = BACKEND_DIR.parent / "frontend" / "dist"

if FRONTEND_DIST.exists():
    assets_dir = FRONTEND_DIST / "assets"
    if assets_dir.exists():
        app.mount("/assets", StaticFiles(directory=str(assets_dir)), name="assets")

    @app.get("/{full_path:path}")
    def spa_fallback(full_path: str) -> FileResponse:
        if full_path:
            candidate = FRONTEND_DIST / full_path
            if candidate.exists() and candidate.is_file():
                return FileResponse(str(candidate))
        return FileResponse(str(FRONTEND_DIST / "index.html"))
