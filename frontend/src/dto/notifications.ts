import type { Company } from "./companies";
import type { Speaker } from "./speakers";

export type NotificationKind =
  | "CREATED"
  | "UPDATED"
  | "DELETED"
  | "TAGGED"
  | "UPDATED_PRIVATE_IMAGE"
  | "UPDATED_PUBLIC_IMAGE"
  | "UPLOADED_MEETING_MINUTE"
  | "DELETED_MEETING_MINUTE"
  | "UPDATED_COMPANY_IMAGE"
  | "CREATED_PARTICIPATION"
  | "UPDATED_PARTICIPATION"
  | "DELETED_PARTICIPATION"
  | "CREATED_PARTICIPATION_PACKAGE"
  | "UPDATED_PARTICIPATION_PACKAGE"
  | "DELETED_PARTICIPATION_PACKAGE"
  | "CREATED_PARTICIPATION_BILLING"
  | "DELETED_PARTICIPATION_BILLING"
  | "UPDATED_PARTICIPATION_STATUS";

export interface Notification {
  id: string; // maps to _id on backend
  kind: NotificationKind;
  signature?: string;
  member?: string; // member that should receive or generated it
  date?: string; // ISO date string
  // optional references to entities
  event?: number;
  // company/speaker can be either the id (string) or an embedded object
  company?: string | Company;
  speaker?: string | Speaker;
  meeting?: string;
  thread?: string;
  post?: string;
  name?: string; // human-friendly name of the target entity
}
