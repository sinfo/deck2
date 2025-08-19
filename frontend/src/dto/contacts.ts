import type { ObjectID } from ".";

export interface ContactPhone {
  phone: string;
  valid: boolean;
}

export interface ContactSocials {
  facebook?: string;
  skype?: string;
  github?: string;
  twitter?: string;
  linkedin?: string;
}

export interface ContactMail {
  mail: string;
  personal: boolean;
  valid: boolean;
}

export enum Gender {
  MALE = "MALE",
  FEMALE = "FEMALE",
  OTHER = "OTHER",
}

export enum Language {
  PORTUGUESE = "PORTUGUESE",
  ENGLISH = "ENGLISH",
}

export interface Contact {
  id: ObjectID;
  gender: Gender;
  language: Language;
  phones: ContactPhone[];
  socials: ContactSocials;
  mails: ContactMail[];
}

export interface CreateContactData {
  gender?: Gender;
  language?: Language;
  phones: ContactPhone[];
  socials: ContactSocials;
  mails: ContactMail[];
}
