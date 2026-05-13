import type {
  ChooseResult,
  PuzzleMeta,
  Snapshot,
  Status,
} from "./types";

async function http<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(path, {
    ...init,
    headers: {
      "content-type": "application/json",
      ...(init?.headers ?? {}),
    },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`${res.status} ${res.statusText}: ${text}`);
  }
  return (await res.json()) as T;
}

export function listPuzzles(): Promise<{ puzzles: PuzzleMeta[] }> {
  return http("/api/puzzles");
}

export function newGame(puzzleId?: string): Promise<Snapshot> {
  return http("/api/game/new", {
    method: "POST",
    body: JSON.stringify({ puzzle_id: puzzleId ?? null }),
  });
}

export function choose(cell: string, status: Status): Promise<ChooseResult> {
  return http("/api/game/choose", {
    method: "POST",
    body: JSON.stringify({ cell, status }),
  });
}

export function hint(
  level: 1 | 2
): Promise<{
  highlighted_clues?: { cell: string; text: string }[];
  highlighted_cells?: string[];
  snapshot: Snapshot;
}> {
  return http("/api/game/hint", {
    method: "POST",
    body: JSON.stringify({ level }),
  });
}

export function resetGame(): Promise<Snapshot> {
  return http("/api/game/reset", { method: "POST" });
}

export function getState(): Promise<Snapshot> {
  return http("/api/game/state");
}

export function getSolution(): Promise<{ solution: Record<string, Status> }> {
  return http("/api/game/solution");
}
