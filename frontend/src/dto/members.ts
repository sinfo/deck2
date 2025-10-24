import type { ObjectID } from ".";
import type { Contact, ContactSocials } from "./contacts";
import type { TeamRole } from "./teams";

export interface Member {
  id: ObjectID;
  name: string;
  img: string;
  istid: string;
  sinfoid: string;
  contact: ObjectID;
}

export interface MemberWithContact extends Member {
  contactObject: Contact;
}

export interface MemberPublic {
  name: string;
  img: string;
  socials: ContactSocials;
}

export interface AuthorizationCredentials {
  id: ObjectID;
  sinfoid: string;
  role: TeamRole;
  team: string;
}

export const getMemberTeamName = (
  credentials: AuthorizationCredentials,
): string => {
  // Teams follow "Team (edition)"
  return credentials.team.split(" (")[0];
};

export interface JWTAuth extends AuthorizationCredentials {
  exp: number;
}

export interface MemberEventTeam {
  event: number;
  team: string;
  role: TeamRole;
}

export interface AllMembersFilter {
  name?: string;
  event?: number;
}
