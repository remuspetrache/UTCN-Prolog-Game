import { useRef, useState } from "react";
import type { Character, Status } from "../types";

export type CornerColor = "green" | "yellow" | "red" | null;

interface Props {
  character: Character;
  knownStatus?: Status;
  hasClue: boolean;
  clueText?: string;
  hintRevealed: boolean;
  hasMistake: boolean;
  highlightedByHint: boolean;
  cornerColor: CornerColor;
  paletteColor: string | null;
  onOpenChoice: () => void;
  onCycleCorner: () => void;
  onOpenPalette: (x: number, y: number) => void;
}

export function CharacterCard(props: Props) {
  const {
    character,
    knownStatus,
    hasClue,
    clueText,
    hintRevealed,
    hasMistake,
    highlightedByHint,
    cornerColor,
    paletteColor,
    onOpenChoice,
    onCycleCorner,
    onOpenPalette,
  } = props;

  const rootRef = useRef<HTMLDivElement>(null);
  const pressTimer = useRef<number | undefined>(undefined);
  const [pressed, setPressed] = useState(false);

  function startLongPress(e: React.MouseEvent | React.TouchEvent) {
    setPressed(true);
    pressTimer.current = window.setTimeout(() => {
      const rect = rootRef.current?.getBoundingClientRect();
      if (rect) {
        onOpenPalette(rect.right - 12, rect.top + 4);
      }
    }, 450);
  }
  function cancelLongPress() {
    if (pressTimer.current) {
      window.clearTimeout(pressTimer.current);
      pressTimer.current = undefined;
    }
    setPressed(false);
  }

  const classes = ["character"];
  if (knownStatus) {
    classes.push(hasClue ? "known-clue" : "known-correct");
  }
  if (hintRevealed) classes.push("hint-revealed");
  if (hasMistake && !knownStatus) classes.push("mistake");
  if (highlightedByHint) classes.push("highlighted");

  return (
    <div
      ref={rootRef}
      className={classes.join(" ")}
      style={paletteColor ? { outline: `3px solid ${paletteColor}`, outlineOffset: "-2px" } : undefined}
      onClick={(e) => {
        if (pressed && pressTimer.current === undefined) return;
        cancelLongPress();
        if (!knownStatus) onOpenChoice();
      }}
      onContextMenu={(e) => {
        e.preventDefault();
        onCycleCorner();
      }}
      onMouseDown={startLongPress}
      onMouseUp={cancelLongPress}
      onMouseLeave={cancelLongPress}
      onTouchStart={startLongPress}
      onTouchEnd={cancelLongPress}
      title={character.name}
    >
      <span className="cell-id">{character.cell}</span>
      {cornerColor && <span className={`corner-tag ${cornerColor}`} />}
      <div className="name">{character.name}</div>
      <div className="role">{character.role}</div>
      <div className="group">{character.group}</div>
      {clueText && (
        <div
          className={`cell-clue${highlightedByHint ? " highlighted" : ""}`}
          title={clueText}
        >
          {clueText}
        </div>
      )}
      {knownStatus && (
        <span className={`status-tag ${knownStatus}`}>
          {knownStatus === "integralist" ? "Integralist" : "Restantier"}
        </span>
      )}
    </div>
  );
}
