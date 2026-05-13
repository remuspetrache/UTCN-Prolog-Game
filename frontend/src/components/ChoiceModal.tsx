import type { Character, Status } from "../types";

interface Props {
  character: Character;
  onChoose: (status: Status) => void;
  onClose: () => void;
}

export function ChoiceModal({ character, onChoose, onClose }: Props) {
  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h2>
          Cine e {character.name}? <span style={{ color: "#888", fontWeight: 500, fontSize: 14 }}>({character.role}, {character.group})</span>
        </h2>
        <div className="choice-row">
          <button
            className="integralist"
            onClick={() => onChoose("integralist")}
          >
            Integralist
          </button>
          <button
            className="restantier"
            onClick={() => onChoose("restantier")}
          >
            Restantier
          </button>
        </div>
        <div className="actions">
          <button className="ghost" onClick={onClose}>
            Anulează
          </button>
        </div>
      </div>
    </div>
  );
}
