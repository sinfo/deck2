import type { ImplementsParticipationStatus, ObjectID, Participation } from ".";
import type { Contact, CreateContactData } from "./contacts";
import type { PackagePublic } from "./packages";
import type { CompanyTasks } from "./tasks";

export interface CompanyParticipation
  extends ImplementsParticipationStatus,
    Participation {
  member: ObjectID;
  communications: ObjectID[];
  subscribers: ObjectID[];
  package?: ObjectID;
  billing?: ObjectID;
  confirmed: string;
  partner: boolean;
  notes: string;
  standDetails?: StandDetails;
  stands?: Stand[];
  tasks?: CompanyTasks;
}

export interface Stand {
  standId: string;
  date?: string;
}

export interface StandDetails {
  chairs: number;
  table: boolean;
  lettering: boolean;
}

export interface CompanyBillingInfo {
  name: string;
  address: string;
  tin: string;
}

export interface CompanyImages {
  internal: string;
  public: string;
}

export interface Company {
  id: ObjectID;
  name: string;
  description: string;
  imgs?: CompanyImages;
  site: string;
  linkedin?: string;
  employers?: ObjectID[];
  billingInfo?: CompanyBillingInfo;
  participations: CompanyParticipation[];
  contact: ObjectID;
  relationships?: CompanyRelationship[];
}

export type CompanyRelationshipType =
  | "SUBSIDIARY_OF"
  | "PARENT_OF"
  | "MERGED_INTO"
  | "ABSORBED"
  | "REBRANDED_TO"
  | "REBRANDED_FROM";

// Label of each relationship type, as seen from the company that holds it.
export const companyRelationshipLabels: Record<
  CompanyRelationshipType,
  string
> = {
  SUBSIDIARY_OF: "Part of",
  PARENT_OF: "Owns",
  MERGED_INTO: "Merged into",
  ABSORBED: "Absorbed",
  REBRANDED_TO: "Now known as",
  REBRANDED_FROM: "Formerly known as",
};

export interface CompanyRelationship {
  type: CompanyRelationshipType;
  company: ObjectID;
  since?: string;
  notes?: string;
}

// A CompanyRelationship resolved with the related company's name and image.
export interface RelatedCompany extends CompanyRelationship {
  name: string;
  img?: string;
}

export interface AddCompanyRelationshipData {
  type: CompanyRelationshipType;
  company: ObjectID;
  since?: string;
  notes?: string;
}

export interface CompanyParticipationPublic {
  event: number;
  partner: boolean;
  package?: PackagePublic;
  standDetails?: StandDetails;
  stands?: Stand[];
}

export interface CompanyPublic {
  id: ObjectID;
  name: string;
  img?: string;
  site?: string;
  participation?: CompanyParticipationPublic[];
}

export interface AllCompaniesFilter {
  name?: string;
  event?: number;
  member?: ObjectID;
  partner?: boolean;
}

export interface CompanyWithParticipation extends Company {
  participation?: CompanyParticipation;
}

export interface UpdateCompanyParticipationData {
  member?: ObjectID;
  partner?: boolean;
  confirmed?: string | null;
  notes?: string;
}

export interface AddParticipationData {
  partner: boolean;
}

export interface CompanyRep {
  id: ObjectID;
  name: string;
  contact: Contact;
}

export interface CreateCompanyRepData {
  name?: string;
  contact?: CreateContactData;
}

export interface UpdateCompanyData {
  name?: string;
  description?: string;
  site?: string;
  linkedin?: string;
  billingInfo?: CompanyBillingInfo;
}

export interface CreateCompanyData {
  name: string;
  description?: string;
  site?: string;
  linkedin?: string;
}
