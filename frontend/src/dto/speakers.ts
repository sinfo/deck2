import type { ImplementsParticipationStatus, ObjectID, Participation } from ".";
import type { Contact, CreateContactData } from "./contacts";

export interface SpeakerParticipationRoom {
  type: string;
  cost: number;
  notes: string;
}

export interface SpeakerParticipation
  extends ImplementsParticipationStatus,
    Participation {
  member: ObjectID;
  communications: ObjectID[];
  subscribers: ObjectID[];
  feedback: string;
  flights: ObjectID[];
  room: SpeakerParticipationRoom;
}

export interface SpeakerImages {
  internal: string;
  speaker: string;
  company: string;
}

export interface Speaker {
  id: ObjectID;
  name: string;
  contact?: ObjectID;
  title: string;
  bio: string;
  companyName: string;
  notes: string;
  imgs: SpeakerImages;
  participations: SpeakerParticipation[];
}

export const isSpeaker = (entity: unknown): entity is Speaker => {
  return (
    typeof entity === "object" && entity !== null && "companyName" in entity
  );
};

export interface SpeakerWithContactObject extends Speaker {
  contactObject: Contact;
}

export interface SpeakerImagesPublic {
  speaker: string;
  company?: string;
}

export interface SpeakerParticipationPublic {
  event: number;
  feedback: string;
}

export interface SpeakerPublic {
  id: ObjectID;
  name: string;
  title: string;
  bio: string;
  companyName?: string;
  imgs: SpeakerImagesPublic;
  participation: SpeakerParticipationPublic[];
}

export interface SpeakerWithParticipation extends Speaker {
  participation?: SpeakerParticipation;
}

export interface AllSpeakersFilter {
  name?: string;
  event?: number;
  member?: ObjectID;
}

export interface CreateSpeakerData {
  name: string;
  title: string;
  bio: string;
  companyName: string;
  notes?: string;
  contact: CreateContactData;
}

export interface UpdateSpeakerData {
  name?: string;
  title?: string;
  bio?: string;
  companyName?: string;
  notes?: string;
}

export interface UpdateSpeakerParticipationData {
  member?: ObjectID;
  feedback?: string;
  room?: SpeakerParticipationRoom;
}
