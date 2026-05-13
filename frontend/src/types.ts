export type Status = "integralist" | "restantier";

export interface Character {
  cell: string;
  name: string;
  role: string;
  group: string;
}

export interface KnownCell {
  cell: string;
  status: Status;
}

export interface RevealedClue {
  cell: string;
  text: string;
  term?: string;
}

export interface Mistake {
  cell: string;
  status: Status;
}

export interface Snapshot {
  puzzle_id?: string;
  title?: string | null;
  difficulty?: string | null;
  revealed_at_start?: string | null;
  characters: Character[];
  known: KnownCell[];
  revealed_clues: RevealedClue[];
  mistakes: Mistake[];
  hinted: string[];
  won: boolean;
}

export interface ChooseResult {
  ok: boolean;
  reason?: "not_enough_evidence" | "wrong_status";
  actual_status?: Status;
  revealed_clue?: RevealedClue | null;
  snapshot: Snapshot;
}

export interface PuzzleMeta {
  id: string;
  filename: string;
}
