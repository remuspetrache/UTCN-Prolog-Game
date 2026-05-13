interface Props {
  reason: "not_enough_evidence" | "wrong_status";
  onClose: () => void;
}

export function WrongModal({ reason, onClose }: Props) {
  const title =
    reason === "not_enough_evidence"
      ? "Nu ai destule indicii!"
      : "Alegere greșită!";
  const body =
    reason === "not_enough_evidence"
      ? "Nu există încă suficiente indicii pentru a dovedi complet acest lucru. Descoperă mai multe indicii mai întâi."
      : "Indiciile arată clar contrariul. Ai acumulat o greșeală — mai încearcă.";
  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h2>{title}</h2>
        <p style={{ marginTop: 4, color: "#444", lineHeight: 1.5 }}>{body}</p>
        <div className="actions">
          <button onClick={onClose}>Am înțeles</button>
        </div>
      </div>
    </div>
  );
}
