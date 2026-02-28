import type { Participation, ObjectID } from ".";
import type { CompanyBillingInfo, CompanyParticipation } from "./companies";
import type { SpeakerParticipation } from "./speakers";

/**
 * Discriminator for entity types that share the Tasks timeline.
 */
export type EntityType = "company" | "speaker";

/**
 * A unified participation type used across task components.
 * Company participations carry extra fields (package, billing, confirmed, etc.)
 * while speaker participations carry their own (feedback, flights, room, etc.).
 */
export type AnyParticipation = CompanyParticipation | SpeakerParticipation;

/**
 * Minimal shape every entity must satisfy to be used in the Tasks view.
 */
export interface TaskEntity {
  id: ObjectID;
  name: string;
  participation?: Participation;
  billingInfo?: CompanyBillingInfo;
}
