import type { ObjectID } from ".";
import type { CreateMeetingData } from "./meetings";
import type { Post } from "./post";

export interface ThreadWithEntry {
  id: ObjectID;
  posted: string;
  entry?: Post;
  meeting?: ObjectID;
  comments: ObjectID[];
  kind: ThreadKind;
  status: ThreadStatus;
  gmailMessageId?: string;
}

export enum ThreadKind {
  ThreadKindTemplate = "TEMPLATE",
  ThreadKindTo = "TO",
  ThreadKindFrom = "FROM",
  ThreadKindPhoneCall = "PHONE_CALL",
  ThreadKindMeeting = "MEETING",
}

export enum ThreadStatus {
  ThreadStatusApproved = "APPROVED",
  ThreadStatusReviewed = "REVIEWED",
  ThreadStatusPending = "PENDING",
}

export interface CreateThread {
  text?: string;
  meeting?: CreateMeetingData;
  kind?: ThreadKind;
}

export interface ParticipationCommunications {
  event: number;
  communications: ThreadWithEntry[];
  gmailThreadIds?: string[];
}
