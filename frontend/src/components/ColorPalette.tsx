import { useEffect, useRef } from "react";

export const PALETTE = [
  "#e53935",
  "#fb8c00",
  "#fdd835",
  "#43a047",
  "#1e88e5",
  "#8e24aa",
  "#795548",
];

interface Props {
  x: number;
  y: number;
  onPick: (color: string | null) => void;
  onClose: () => void;
}

export function ColorPalette({ x, y, onPick, onClose }: Props) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        onClose();
      }
    };
    window.addEventListener("mousedown", handler);
    return () => window.removeEventListener("mousedown", handler);
  }, [onClose]);

  return (
    <div
      ref={ref}
      className="palette-popover"
      style={{ left: x, top: y }}
      onClick={(e) => e.stopPropagation()}
    >
      {PALETTE.map((c) => (
        <div
          key={c}
          className="palette-swatch"
          style={{ background: c }}
          onClick={() => onPick(c)}
        />
      ))}
      <div
        className="palette-swatch clear"
        title="Șterge culoarea"
        onClick={() => onPick(null)}
      />
    </div>
  );
}
