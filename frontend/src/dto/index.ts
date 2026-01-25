export type ObjectID = string;

export interface Participation {
  event: number;
  gmailThreadIds?: string[];
}

export interface ImplementsParticipationStatus {
  status: ParticipationStatus;
}

export type ParticipationStatus =
  | "SUGGESTED"
  | "SELECTED"
  | "ON_HOLD"
  | "CONTACTED"
  | "IN_CONVERSATIONS"
  | "ACCEPTED"
  | "REJECTED"
  | "GIVEN_UP"
  | "ANNOUNCED";
export const participationNextValues: Record<
  ParticipationStatus,
  ParticipationStatus[]
> = {
  SUGGESTED: ["SELECTED", "ON_HOLD"],
  SELECTED: ["CONTACTED"],
  ON_HOLD: ["SELECTED"],
  CONTACTED: ["IN_CONVERSATIONS", "REJECTED", "GIVEN_UP"],
  IN_CONVERSATIONS: ["ACCEPTED", "REJECTED", "GIVEN_UP"],
  ACCEPTED: ["ANNOUNCED"],
  REJECTED: [],
  GIVEN_UP: [],
  ANNOUNCED: [],
};

export const humanReadableParticipationStatus: Record<
  ParticipationStatus,
  string
> = {
  SUGGESTED: "Suggested",
  SELECTED: "Selected",
  ON_HOLD: "On Hold",
  CONTACTED: "Contacted",
  IN_CONVERSATIONS: "In Conversations",
  ACCEPTED: "Accepted",
  REJECTED: "Rejected",
  GIVEN_UP: "Given Up",
  ANNOUNCED: "Announced",
};

interface ParticipationStatusColor {
  background: string;
  ring: string;
}
export const participationStatusColor: Record<
  ParticipationStatus,
  ParticipationStatusColor
> = {
  SUGGESTED: { background: "bg-amber-300", ring: "ring-amber-200" }, //
  SELECTED: { background: "bg-violet-400", ring: "ring-violet-500/50" }, //
  ON_HOLD: { background: "bg-zinc-400", ring: "ring-zinc-500/50" },
  CONTACTED: { background: "bg-orange-300", ring: "ring-orange-300/50" }, //
  IN_CONVERSATIONS: { background: "bg-sky-400", ring: "ring-sky-400/50" }, //
  ACCEPTED: { background: "bg-lime-400", ring: "ring-lime-400/50" }, //
  REJECTED: { background: "bg-red-400", ring: "ring-red-400/50" }, //
  GIVEN_UP: { background: "", ring: "ring-black" }, //
  ANNOUNCED: { background: "bg-green-600", ring: "ring-green-700/50" }, //
};

// Next advances status of participation.
// This follows a state machine well defined.
//   SUGGESTED
//      1 => SELECTED
//      2 => ON_HOLD
//   SELECTED
//      1 => CONTACTED
//   ON_HOLD
//      1 => SELECTED
//   CONTACTED
//      1 => IN_CONVERSATIONS
//      2 => REJECTED
//      3 => GIVEN_UP
//   IN_CONVERSATIONS
//      1 => ACCEPTED
//      2 => REJECTED
//      3 => GIVEN_UP
//   ACCEPTED
//      1 => ANNOUNCED
export const nextParticipationStatus = (
  status: ParticipationStatus,
  step: number,
): ParticipationStatus => {
  switch (status) {
    case "SUGGESTED":
      if (step === 1) return "SELECTED";
      if (step === 2) return "ON_HOLD";
      break;

    case "SELECTED":
      if (step === 1) return "CONTACTED";
      break;

    case "ON_HOLD":
      if (step === 1) return "SELECTED";
      break;

    case "CONTACTED":
      if (step === 1) return "IN_CONVERSATIONS";
      if (step === 2) return "REJECTED";
      if (step === 3) return "GIVEN_UP";
      break;

    case "IN_CONVERSATIONS":
      if (step === 1) return "ACCEPTED";
      if (step === 2) return "REJECTED";
      if (step === 3) return "GIVEN_UP";
      break;

    case "ACCEPTED":
      if (step === 1) return "ANNOUNCED";
      break;
  }

  return status; // If no valid transition, return the same status
};
