import type { ObjectID } from ".";

export interface MeetingParticipants {
  members: ObjectID[];
  companyReps: ObjectID[];
}

export enum MeetingKind {
  EVENT = "EVENT",
  TEAM = "TEAM",
  COMPANY = "COMPANY",
}

export enum MeetingParticipantKind {
  MEMBER = "MEMBER",
  COMPANYREP = "COMPANYREP",
}

export interface Meeting {
  id: ObjectID;
  title: string;
  kind: MeetingKind;
  begin: string;
  end: string;
  place: string;
  minute: string;
  communications: ObjectID[];
  participants: MeetingParticipants;
}

export interface CreateMeetingData {
  title?: string;
  kind?: string;
  begin?: string;
  end?: string;
  place?: string;
  participants?: MeetingParticipants;
}

export interface GetMeetingsOptions {
  event?: number;
  team?: ObjectID;
  company?: ObjectID;
}

export interface UpdateMeetingData {
  title: string;
  kind: string;
  begin: string;
  end: string;
  place: string;
}

export interface MeetingParticipantData {
  memberID: ObjectID;
  type: string;
}
