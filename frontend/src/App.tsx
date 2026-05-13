import { useCallback, useEffect, useMemo, useState } from "react";
import { choose, getState, hint, listPuzzles, newGame, resetGame } from "./api";
import { CharacterCard, type CornerColor } from "./components/CharacterCard";
import { ChoiceModal } from "./components/ChoiceModal";
import { ColorPalette } from "./components/ColorPalette";
import { EndPopup } from "./components/EndPopup";
import { Timer } from "./components/Timer";
import { WrongModal } from "./components/WrongModal";
import type { Character, PuzzleMeta, Snapshot, Status } from "./types";

const CORNER_CYCLE: CornerColor[] = ["green", "yellow", "red", null];

export default function App() {
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null);
  const [puzzles, setPuzzles] = useState<PuzzleMeta[]>([]);
  const [selectedPuzzle, setSelectedPuzzle] = useState<string>("");
  const [timerRunning, setTimerRunning] = useState(false);
  const [resetKey, setResetKey] = useState(0);
  const [elapsed, setElapsed] = useState(0);
  const [openChoice, setOpenChoice] = useState<Character | null>(null);
  const [wrong, setWrong] = useState<"not_enough_evidence" | "wrong_status" | null>(null);
  const [corners, setCorners] = useState<Record<string, CornerColor>>({});
  const [paletteColors, setPaletteColors] = useState<Record<string, string | null>>({});
  const [paletteFor, setPaletteFor] = useState<{ cell: string; x: number; y: number } | null>(null);
  const [highlightedClues, setHighlightedClues] = useState<Set<string>>(new Set());
  const [hintedCells, setHintedCells] = useState<Set<string>>(new Set());
  const [dimmedCells, setDimmedCells] = useState<Set<string>>(new Set());
  const [endOpen, setEndOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const loadPuzzles = useCallback(async () => {
    try {
      const { puzzles } = await listPuzzles();
      setPuzzles(puzzles);
      if (!selectedPuzzle && puzzles.length > 0) {
        setSelectedPuzzle(puzzles[0].id);
      }
    } catch (e) {
      setError(String(e));
    }
  }, [selectedPuzzle]);

  useEffect(() => {
    loadPuzzles();
    getState()
      .then((s) => setSnapshot(s))
      .catch(() => {});
  }, [loadPuzzles]);

  useEffect(() => {
    if (!timerRunning) return;
    const id = window.setInterval(() => setElapsed((v) => v + 1), 1000);
    return () => window.clearInterval(id);
  }, [timerRunning]);

  const startGame = async (puzzleId?: string) => {
    const snap = await newGame(puzzleId ?? (selectedPuzzle || undefined));
    setSnapshot(snap);
    setCorners({});
    setPaletteColors({});
    setHighlightedClues(new Set());
    setHintedCells(new Set());
    setDimmedCells(new Set());
    setResetKey((k) => k + 1);
    setElapsed(0);
    setTimerRunning(false);
    setEndOpen(false);
  };

  const handleChoice = async (character: Character, status: Status) => {
    setOpenChoice(null);
    if (!timerRunning) setTimerRunning(true);
    try {
      const result = await choose(character.cell, status);
      setSnapshot(result.snapshot);
      if (!result.ok) {
        setWrong(result.reason ?? "wrong_status");
      }
      if (result.snapshot.won) {
        setTimerRunning(false);
        setEndOpen(true);
      }
    } catch (e) {
      setError(String(e));
    }
  };

  const cycleCorner = (cell: string) => {
    setCorners((prev) => {
      const idx = CORNER_CYCLE.indexOf(prev[cell] ?? null);
      return { ...prev, [cell]: CORNER_CYCLE[(idx + 1) % CORNER_CYCLE.length] };
    });
  };

  const toggleDim = (cell: string) => {
    setDimmedCells((prev) => {
      const next = new Set(prev);
      if (next.has(cell)) next.delete(cell);
      else next.add(cell);
      return next;
    });
  };

  const onPickColor = (cell: string, color: string | null) => {
    setPaletteColors((prev) => ({ ...prev, [cell]: color }));
    setPaletteFor(null);
  };

  const triggerHint = async () => {
    if (!snapshot) return;
    const level = highlightedClues.size === 0 ? 1 : 2;
    const res = await hint(level as 1 | 2);
    setSnapshot(res.snapshot);
    if (level === 1) {
      const cells = new Set((res.highlighted_clues ?? []).map((c) => c.cell));
      setHighlightedClues(cells);
    } else {
      const cells = new Set(res.highlighted_cells ?? []);
      setHintedCells(cells);
      setHighlightedClues(new Set());
    }
  };

  const doReset = async () => {
    const snap = await resetGame();
    setSnapshot(snap);
    setCorners({});
    setPaletteColors({});
    setHighlightedClues(new Set());
    setHintedCells(new Set());
    setDimmedCells(new Set());
    setResetKey((k) => k + 1);
    setElapsed(0);
    setTimerRunning(false);
    setEndOpen(false);
  };

  const cells = useMemo(() => {
    const rows = [1, 2, 3, 4, 5];
    const cols = ["a", "b", "c", "d"];
    return rows.flatMap((r) => cols.map((c) => `${c}${r}`));
  }, []);

  const charByCell = useMemo(() => {
    const m = new Map<string, Character>();
    snapshot?.characters.forEach((c) => m.set(c.cell, c));
    return m;
  }, [snapshot]);

  const knownByCell = useMemo(() => {
    const m = new Map<string, Status>();
    snapshot?.known.forEach((k) => m.set(k.cell, k.status));
    return m;
  }, [snapshot]);

  const mistakesByCell = useMemo(() => {
    const s = new Set<string>();
    snapshot?.mistakes.forEach((m) => s.add(m.cell));
    return s;
  }, [snapshot]);

  const cluesByCell = useMemo(() => {
    const m = new Map<string, string>();
    snapshot?.revealed_clues.forEach((c) => m.set(c.cell, c.text));
    return m;
  }, [snapshot]);

  return (
    <div className="app">
      <div className="header">
        <div>
          <h1>UTCN Clues - integralist vs restantier</h1>
          <div className="subtitle">
            Joc inspirat de "Clues by Sam". Implementare bazata pe Prolog
          </div>
        </div>
        <div className="toolbar">
          <select
            value={selectedPuzzle}
            onChange={(e) => setSelectedPuzzle(e.target.value)}
          >
            {puzzles.map((p) => (
              <option key={p.id} value={p.id}>
                {p.id}
              </option>
            ))}
          </select>
          <button onClick={() => startGame()}>Joc nou</button>
          <button className="ghost" onClick={doReset}>
            Resetează
          </button>
          <button className="warn" onClick={triggerHint}>
            Hint ({highlightedClues.size === 0 ? "indicii" : "personaje"})
          </button>
          <Timer running={timerRunning} resetKey={resetKey} />
        </div>
      </div>

      {error && <div className="status-banner">Eroare: {error}</div>}

      <div className="board">
        {cells.map((cell) => {
          const ch = charByCell.get(cell);
          if (!ch) return <div key={cell} />;
          return (
            <CharacterCard
              key={cell}
              character={ch}
              knownStatus={knownByCell.get(cell)}
              hasClue={cluesByCell.has(cell)}
              clueText={cluesByCell.get(cell)}
              hintRevealed={hintedCells.has(cell) || (snapshot?.hinted ?? []).includes(cell)}
              hasMistake={mistakesByCell.has(cell)}
              highlightedByHint={highlightedClues.has(cell)}
              cornerColor={corners[cell] ?? null}
              paletteColor={paletteColors[cell] ?? null}
              dimmed={dimmedCells.has(cell)}
              onOpenChoice={() => setOpenChoice(ch)}
              onCycleCorner={() => cycleCorner(cell)}
              onOpenPalette={(x, y) => setPaletteFor({ cell, x, y })}
              onToggleDim={() => toggleDim(cell)}
            />
          );
        })}
      </div>

      {openChoice && (
        <ChoiceModal
          character={openChoice}
          onChoose={(status) => handleChoice(openChoice, status)}
          onClose={() => setOpenChoice(null)}
        />
      )}

      {wrong && <WrongModal reason={wrong} onClose={() => setWrong(null)} />}

      {paletteFor && (
        <ColorPalette
          x={paletteFor.x}
          y={paletteFor.y}
          onPick={(c) => onPickColor(paletteFor.cell, c)}
          onClose={() => setPaletteFor(null)}
        />
      )}

      {endOpen && snapshot && (
        <EndPopup
          snapshot={snapshot}
          elapsedSeconds={elapsed}
          onClose={() => setEndOpen(false)}
        />
      )}
    </div>
  );
}
