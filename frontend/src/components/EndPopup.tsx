import type { Snapshot } from "../types";

interface Props {
  snapshot: Snapshot;
  elapsedSeconds: number;
  onClose: () => void;
}

export function EndPopup({ snapshot, elapsedSeconds, onClose }: Props) {
  const rows = [1, 2, 3, 4, 5];
  const cols = ["a", "b", "c", "d"];
  const known = new Map(snapshot.known.map((k) => [k.cell, k.status]));
  const mistakes = new Map<string, number>();
  for (const m of snapshot.mistakes) {
    mistakes.set(m.cell, (mistakes.get(m.cell) ?? 0) + 1);
  }
  const hinted = new Set(snapshot.hinted);
  const mm = Math.floor(elapsedSeconds / 60);
  const ss = elapsedSeconds % 60;
  const time = `${mm}:${ss.toString().padStart(2, "0")}`;

  const correctCount = snapshot.known.filter((k) => !hinted.has(k.cell)).length;

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal" style={{ minWidth: 380 }} onClick={(e) => e.stopPropagation()}>
        <h2>{snapshot.won ? "Felicitări!" : "Rezultat partial"}</h2>
        <div style={{ display: "flex", gap: 14, flexWrap: "wrap", marginBottom: 6 }}>
          <div className="badge">Timp: {time}</div>
          <div className="badge">Corecte: {correctCount}/20</div>
          <div className={`badge ${snapshot.mistakes.length ? "warn" : ""}`}>
            Greșeli: {snapshot.mistakes.length}
          </div>
          <div className="badge">Hint-uri: {hinted.size}</div>
        </div>
        <div className="end-grid">
          {rows.flatMap((r) =>
            cols.map((c) => {
              const cell = `${c}${r}`;
              const hasMistake = (mistakes.get(cell) ?? 0) > 0;
              const isHinted = hinted.has(cell);
              const isKnown = known.has(cell);
              let cls = "blank";
              if (isHinted) cls = "orange";
              else if (hasMistake && isKnown) cls = "yellow";
              else if (hasMistake) cls = "yellow";
              else if (isKnown) cls = "green";
              return (
                <div key={cell} className={`end-cell ${cls}`}>
                  {cell.toUpperCase()}
                </div>
              );
            })
          )}
        </div>
        <div style={{ fontSize: 12, color: "#555", lineHeight: 1.5 }}>
          Verde = ghicit corect fără hint. Galben = ai greșit pe acest caracter.
          Portocaliu = dezvăluit cu un hint.
        </div>
        <div className="actions">
          <button onClick={onClose}>Închide</button>
        </div>
      </div>
    </div>
  );
}
