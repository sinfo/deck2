import type { ObjectID } from ".";

export type TeamRole = "MEMBER" | "TEAMLEADER" | "COORDINATOR" | "ADMIN";

export interface TeamMember {
  member: ObjectID;
  role: TeamRole;
}

export interface Team {
  id: ObjectID;
  name: string;
  members: TeamMember[];
  meetings: ObjectID[];
}

export interface TeamPublic {
  id: ObjectID;
  name: string;
  members: TeamMember[];
}
