import type { ObjectID } from ".";
import type { TeamMember } from "./teams";

export interface CoordinationTeam {
  id: ObjectID;
  name: string;
  coordinator?: TeamMember | null;
  coordinatedMembers: ObjectID[];
}

export interface CreateCoordinationTeamData {
  coordinator: ObjectID;
}

export interface AddCoordinatedTeamData {
  member: ObjectID;
}

export interface SetCoordinatorData {
  member: ObjectID;
  name?: string;
}
