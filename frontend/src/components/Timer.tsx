import { useEffect, useState } from "react";

interface Props {
  running: boolean;
  resetKey: number;
}

export function Timer({ running, resetKey }: Props) {
  const [seconds, setSeconds] = useState(0);

  useEffect(() => {
    setSeconds(0);
  }, [resetKey]);

  useEffect(() => {
    if (!running) return;
    const id = window.setInterval(() => setSeconds((s) => s + 1), 1000);
    return () => window.clearInterval(id);
  }, [running]);

  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  const label =
    seconds < 300 ? `${m}:${s.toString().padStart(2, "0")}` : `${m}m`;
  return <div className="timer">{label}</div>;
}
