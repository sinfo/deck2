import type { ImplementsParticipationStatus, ObjectID, Participation } from ".";
import type { Contact, CreateContactData } from "./contacts";
import type { PackagePublic } from "./packages";

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
  employers?: ObjectID[];
  billingInfo?: CompanyBillingInfo;
  participations: CompanyParticipation[];
  contact: ObjectID;
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
  description: string;
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
  confirmed?: string;
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
  billingInfo?: CompanyBillingInfo;
}

export interface CreateCompanyData {
  name: string;
  description?: string;
  site?: string;
}
