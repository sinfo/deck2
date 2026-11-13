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

// ============================================================
// Shared
// ============================================================

export interface TaskLogos {
  received: boolean;
  needsReviewing: boolean;
}

// ============================================================
// Company task types
// ============================================================

export interface CompanyTaskConfirmation {
  askedForInfo: boolean;
}

export interface CompanyTaskContract {
  sent: boolean;
  created: boolean;
  signed: boolean;
  receiptSent: boolean;
  paid: boolean;
}

export interface CompanyTaskSessionTitles {
  presentationTitle: string;
  workshopTitle: string;
}

export interface CompanyTaskCorlief {
  preNotice: boolean;
  scheduled: boolean;
  reserved: boolean;
}

export interface CompanyTaskLogistics {
  requestedInfo: boolean;
  carStatus: string; // "not_responded" | "wants" | "not_wants"
  licensePlate: string;
}

export interface CompanyTasks {
  confirmation: CompanyTaskConfirmation;
  logos: TaskLogos;
  contract: CompanyTaskContract;
  sessionTitles: CompanyTaskSessionTitles;
  corlief: CompanyTaskCorlief;
  logistics: CompanyTaskLogistics;
  po: string;
}

// ============================================================
// Speaker task types
// ============================================================

export interface SpeakerTaskConfirmation {
  phone: string;
  linkedin: string;
  wantsLinkedinTag: string; // "not_responded" | "yes" | "no"
  observations: string;
}

export interface SpeakerTaskFlightLeg {
  airport: string;
  flightNumber: string;
  date: string | null;
  time: string;
}

export interface SpeakerTaskFlightDetails {
  price: string;
  status: string; // "pending" | "received" | "approved" | "bought"
  link: string;
  bookingRef: string;
}

export interface SpeakerTaskFlightRefund {
  amount: string;
  method: string;
  infoNeeded: string;
  status: string; // "not_started" | "receipt_requested" | "info_requested" | "done"
}

export interface SpeakerTaskFlights {
  needsFlights: string; // "not_responded" | "yes" | "no"
  requested: boolean;
  arrival: SpeakerTaskFlightLeg;
  departure: SpeakerTaskFlightLeg;
  details: SpeakerTaskFlightDetails;
  refund: SpeakerTaskFlightRefund;
}

export interface SpeakerTaskCoverage {
  video: string; // "not_responded" | "yes" | "no"
  streaming: string; // "not_responded" | "yes" | "no"
  photo: string; // "not_responded" | "yes" | "no"
}

export interface SpeakerTaskMaterials {
  requested: boolean;
  talkTitle: string;
  talkDescription: string;
  received: boolean;
  testSchedule: string;
  testDone: boolean;
}

export interface SpeakerTaskHotel {
  needsHotel: string; // "not_responded" | "yes" | "no"
  requested: boolean;
  hotelName: string;
  roomType: string;
  price: string;
  checkIn: string | null;
  checkOut: string | null;
  numNights: string;
  numGuests: string;
  guestNames: string;
  invoice: boolean;
  paid: boolean;
  notes: string;
}

export interface SpeakerTasks {
  confirmation: SpeakerTaskConfirmation;
  logos: TaskLogos;
  askedForInfo: boolean;
  flights: SpeakerTaskFlights;
  coverage: SpeakerTaskCoverage;
  materials: SpeakerTaskMaterials;
  hotel: SpeakerTaskHotel;
}

// ============================================================
// Helpers – build zero-value task objects
// ============================================================

export function emptyCompanyTasks(): CompanyTasks {
  return {
    confirmation: { askedForInfo: false },
    logos: { received: false, needsReviewing: false },
    contract: {
      sent: false,
      created: false,
      signed: false,
      receiptSent: false,
      paid: false,
    },
    sessionTitles: { presentationTitle: "", workshopTitle: "" },
    corlief: { preNotice: false, scheduled: false, reserved: false },
    logistics: {
      requestedInfo: false,
      carStatus: "not_responded",
      licensePlate: "",
    },
    po: "",
  };
}

export function emptySpeakerTasks(): SpeakerTasks {
  return {
    confirmation: {
      phone: "",
      linkedin: "",
      wantsLinkedinTag: "not_responded",
      observations: "",
    },
    logos: { received: false, needsReviewing: false },
    askedForInfo: false,
    flights: {
      needsFlights: "not_responded",
      requested: false,
      arrival: { airport: "", flightNumber: "", date: null, time: "" },
      departure: { airport: "", flightNumber: "", date: null, time: "" },
      details: { price: "", status: "pending", link: "", bookingRef: "" },
      refund: { amount: "", method: "", infoNeeded: "", status: "not_started" },
    },
    coverage: {
      video: "not_responded",
      streaming: "not_responded",
      photo: "not_responded",
    },
    materials: {
      requested: false,
      talkTitle: "",
      talkDescription: "",
      received: false,
      testSchedule: "",
      testDone: false,
    },
    hotel: {
      needsHotel: "not_responded",
      requested: false,
      hotelName: "",
      roomType: "",
      price: "",
      checkIn: null,
      checkOut: null,
      numNights: "",
      numGuests: "",
      guestNames: "",
      invoice: false,
      paid: false,
      notes: "",
    },
  };
}
