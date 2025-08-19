import { type Speaker } from "@/dto/speakers";
import type { Company } from "../dto/companies";
import { ordinalSuffix } from "./utils";
import {
  getMemberTeamName,
  type AuthorizationCredentials,
  type MemberWithContact,
} from "@/dto/members";
import { Language } from "@/dto/contacts";
import type { Event } from "@/dto/events";

// 1. Add new templates here. Always end with "EN" or "PT".
export enum EmailTemplate {
  COMPANIES_EN = "COMPANIES_EN",
  COMPANIES_PT = "COMPANIES_PT",
  SPEAKERS_EN = "SPEAKERS_EN",
  SPEAKERS_PT = "SPEAKERS_PT",
}

// 2. Set the template names here
export const templateHumanReadableNames: Record<EmailTemplate, string> = {
  [EmailTemplate.COMPANIES_EN]: "Companies Invitation - English",
  [EmailTemplate.COMPANIES_PT]: "Companies Invitation - Português",
  [EmailTemplate.SPEAKERS_EN]: "Speakers Invitation - English",
  [EmailTemplate.SPEAKERS_PT]: "Speakers Invitation - Português",
};

// 3. Set the template paths here
export const templatePaths: Record<EmailTemplate, string> = {
  [EmailTemplate.COMPANIES_EN]: "/companies/32-en.html",
  [EmailTemplate.COMPANIES_PT]: "/companies/32-pt.html",
  [EmailTemplate.SPEAKERS_EN]: "/speakers/32-en.html",
  [EmailTemplate.SPEAKERS_PT]: "/speakers/32-pt.html",
};

// 4. Set the company templates and the speaker templates
export const companyTemplates = [
  EmailTemplate.COMPANIES_EN,
  EmailTemplate.COMPANIES_PT,
];
export const speakerTemplates = [
  EmailTemplate.SPEAKERS_EN,
  EmailTemplate.SPEAKERS_PT,
];

// 5. Set the template categories (used on bulk form)
export enum EmailTemplateCategory {
  CONTACT_COMPANY = "CONTACT_COMPANY",
  CONTACT_SPEAKER = "CONTACT_SPEAKER",
}

export const templateCategoryHumanReadable: Record<
  EmailTemplateCategory,
  string
> = {
  [EmailTemplateCategory.CONTACT_COMPANY]: "Contact Companies",
  [EmailTemplateCategory.CONTACT_SPEAKER]: "Contact Speakers",
};

export const companyTemplateCategories: EmailTemplateCategory[] = [
  EmailTemplateCategory.CONTACT_COMPANY,
];

export const speakerTemplateCategories: EmailTemplateCategory[] = [
  EmailTemplateCategory.CONTACT_SPEAKER,
];

export const templateCategoryTemplates: Record<
  EmailTemplateCategory,
  Record<Language, EmailTemplate>
> = {
  [EmailTemplateCategory.CONTACT_COMPANY]: {
    [Language.ENGLISH]: EmailTemplate.COMPANIES_EN,
    [Language.PORTUGUESE]: EmailTemplate.COMPANIES_PT,
  },
  [EmailTemplateCategory.CONTACT_SPEAKER]: {
    [Language.ENGLISH]: EmailTemplate.SPEAKERS_EN,
    [Language.PORTUGUESE]: EmailTemplate.SPEAKERS_PT,
  },
};

// 6. Add new variables here, if needed.
//    You have to edit "getValueFromVariable" if you add new variables as well as the "createEmailVariable" helper
export enum EmailVariableKey {
  Edition = "Edition",
  EditionOrdinal = "EditionOrdinal",
  EventStartDay = "EventStartDay",
  EventEndDay = "EventEndDay",
  EventEndMonth = "EventEndMonth",
  EventEndYear = "EventEndYear",

  Company = "Company",

  Speaker = "Speaker", // speaker name
  Member = "Member", // member name
  MemberEmail = "MemberEmail", // member email, has default value
  MemberPhoneNumber = "MemberPhoneNumber", // member phone number, has default value
  MemberTeam = "MemberTeam", // member team, has default value
  Paragraph = "Paragraph", // paragraph text, has default value
}

// 6.1 Define the mapping between variable keys and their value types
export interface EmailVariableValueMap {
  [EmailVariableKey.Edition]: number;
  [EmailVariableKey.EditionOrdinal]: number;
  [EmailVariableKey.Company]: Company;
  [EmailVariableKey.EventStartDay]: Date;
  [EmailVariableKey.EventEndDay]: Date;
  [EmailVariableKey.EventEndMonth]: Date;
  [EmailVariableKey.EventEndYear]: Date;
  [EmailVariableKey.Speaker]: Speaker;
  [EmailVariableKey.Member]: MemberWithContact;
  [EmailVariableKey.MemberEmail]: MemberWithContact;
  [EmailVariableKey.MemberPhoneNumber]: MemberWithContact;
  [EmailVariableKey.MemberTeam]: AuthorizationCredentials;
  [EmailVariableKey.Paragraph]: string;
}

// 6.2 Update the variables of each entity (company/speaker)
export interface VariablesInput {
  event: Event;
  member: MemberWithContact;
}
export interface SpeakerVariablesInput extends VariablesInput {
  speaker: Speaker;
  paragraph?: string; // Optional paragraph for speaker emails
}
const isSpeakerVariablesInput = (
  input: VariablesInput,
): input is SpeakerVariablesInput => {
  return (input as SpeakerVariablesInput).speaker !== undefined;
};
export interface CompanyVariablesInput extends VariablesInput {
  company: Company;
}
const isCompanyVariablesInput = (
  input: VariablesInput,
): input is CompanyVariablesInput => {
  return (input as CompanyVariablesInput).company !== undefined;
};

export const getVariablesFromType = <T extends VariablesInput>(
  input: T,
): AnyEmailVariableInput[] => {
  const end = new Date(input.event.end || 0);
  const vars: AnyEmailVariableInput[] = [
    createEmailVariable.edition(input.event.id),
    createEmailVariable.editionOrdinal(input.event.id),
    createEmailVariable.eventStartDay(new Date(input.event.begin || 0)),
    createEmailVariable.eventEndDay(end),
    createEmailVariable.eventEndMonth(end),
    createEmailVariable.eventEndYear(end),
    createEmailVariable.member(input.member),
    createEmailVariable.memberEmail(input.member),
    createEmailVariable.memberPhoneNumber(input.member),
  ];

  if (isSpeakerVariablesInput(input)) {
    if (input.paragraph)
      vars.push(createEmailVariable.paragraph(input.paragraph));

    return [...vars, createEmailVariable.speaker(input.speaker)];
  }

  if (isCompanyVariablesInput(input)) {
    return [...vars, createEmailVariable.company(input.company)];
  }

  return vars;
};

// ------------------------------------------------------------------------------------------------------------------
const regex = /{{\.(.*?)}}/g;
const conditionalRegex =
  /{{if\s+\.(.*?)}}\s*(.*?)\s*(?:{{else}}\s*(.*?)\s*)?{{end}}/gs;

const loadTemplate = async (template: EmailTemplate): Promise<string> => {
  const path = templatePaths[template];
  return fetch(`/templates${path}`).then((r) => r.text());
};

const getTemplateVariablesKeys = (templateContent: string): string[] => {
  // Return all text between {{.VarName}} tags
  const variables = [];
  let match;

  while ((match = regex.exec(templateContent)) !== null) {
    variables.push(match[1]);
  }

  return variables;
};

const processConditionals = (
  content: string,
  variables: AnyEmailVariableInput[],
): string => {
  return content.replace(
    conditionalRegex,
    (_match, variableName, ifContent, elseContent) => {
      const variable = variables.find((v) => v.key === variableName);

      // Check if variable exists and has a truthy value
      const hasValue =
        variable &&
        variable.value &&
        (typeof variable.value === "string"
          ? variable.value.trim() !== ""
          : true);

      if (hasValue) {
        return ifContent || "";
      } else {
        return elseContent || "";
      }
    },
  );
};

const months: Record<Language, string[]> = {
  [Language.PORTUGUESE]: [
    "janeiro",
    "fevereiro",
    "março",
    "abril",
    "maio",
    "junho",
    "julho",
    "agosto",
    "setembro",
    "outubro",
    "novembro",
    "dezembro",
  ],
  [Language.ENGLISH]: [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ],
};

// Edit this if you add more variables
const getValueFromVariable = (
  variable: AnyEmailVariableInput,
  language: Language,
): string => {
  switch (variable.key) {
    case EmailVariableKey.Edition: {
      // Edition is a number, convert to string
      return variable.value.toString();
    }

    case EmailVariableKey.EditionOrdinal: {
      // EditionOrdinal is a number, convert to ordinal
      return language === Language.ENGLISH
        ? ordinalSuffix(variable.value)
        : variable.value.toString();
    }

    case EmailVariableKey.Company: {
      // Company is a Company object, return the name
      return variable.value.name;
    }

    case EmailVariableKey.EventStartDay:
    case EmailVariableKey.EventEndDay: {
      // These are already formatted date strings
      return language === Language.ENGLISH
        ? ordinalSuffix(variable.value.getDate())
        : variable.value.getDate().toString();
    }

    case EmailVariableKey.EventEndMonth: {
      return months[language][variable.value.getMonth()];
    }

    case EmailVariableKey.EventEndYear: {
      return variable.value.getFullYear().toString();
    }

    case EmailVariableKey.Speaker: {
      return variable.value.name;
    }

    case EmailVariableKey.Member: {
      return variable.value.name;
    }

    case EmailVariableKey.MemberEmail: {
      return variable.value.contactObject.mails?.[0].mail;
    }

    case EmailVariableKey.MemberPhoneNumber: {
      return variable.value.contactObject.phones?.[0].phone;
    }

    case EmailVariableKey.MemberTeam: {
      return getMemberTeamName(variable.value) || "Member";
    }

    case EmailVariableKey.Paragraph: {
      return variable.value;
    }

    default: {
      // This should never happen with proper typing, but provides fallback
      const exhaustiveCheck: never = variable;
      throw new Error(`Unhandled variable key: ${exhaustiveCheck}`);
    }
  }
};

const languageFromTemplate = (template: EmailTemplate): Language => {
  return template.endsWith("_EN") ? Language.ENGLISH : Language.PORTUGUESE;
};

const getSubject = (content: string): string => {
  // Extract from title tag
  const match = content.match(/<title>(.*?)<\/title>/);
  return match ? match[1] : "";
};

export const loadTemplateAndReplace = async (
  template: EmailTemplate,
  variables: AnyEmailVariableInput[],
) => {
  // Replace all {{.VarName}} variables
  let content = await loadTemplate(template);

  // First, process conditional blocks
  content = processConditionals(content, variables);

  const allVariables = getTemplateVariablesKeys(content);
  const missing = allVariables.filter(
    (variable) => !variables.find((ev) => ev.key === variable),
  );
  if (missing.length > 0) {
    throw new Error(`Missing variables (${missing.join(", ")}) on template`);
  }

  for (const variable of variables) {
    content = content.replace(
      new RegExp(`{{.${variable.key}}}`, "g"),
      getValueFromVariable(variable, languageFromTemplate(template)),
    );
  }

  return {
    subject: getSubject(content),
    body: content,
  };
};

export const loadSignature = async (
  member: MemberWithContact,
  credentials: AuthorizationCredentials,
) => {
  let signature = await fetch(`/templates/signature.html`).then((r) =>
    r.text(),
  );
  const variables = [
    createEmailVariable.member(member),
    createEmailVariable.memberEmail(member),
    createEmailVariable.memberPhoneNumber(member),
    createEmailVariable.memberTeam(credentials),
  ];

  for (const variable of variables) {
    signature = signature.replace(
      new RegExp(`{{.${variable.key}}}`, "g"),
      getValueFromVariable(variable, Language.ENGLISH),
    );
  }

  return signature;
};

export const openTemplateInNewTab = async (
  template: EmailTemplate,
  variables: AnyEmailVariableInput[],
) => {
  const html = await loadTemplateAndReplace(template, variables);

  const blob = new Blob([html.body], { type: "text/html" });
  const url = URL.createObjectURL(blob);
  window.open(url, "_blank");
};

export interface EmailVariable<K extends EmailVariableKey = EmailVariableKey> {
  key: K;
  value: EmailVariableValueMap[K];
  language: Language;
}

export type EmailVariableInput<K extends EmailVariableKey = EmailVariableKey> =
  Omit<EmailVariable<K>, "language">;

// Create a discriminated union type for all possible variables
export type AnyEmailVariableInput =
  | EmailVariableInput<EmailVariableKey.Edition>
  | EmailVariableInput<EmailVariableKey.EditionOrdinal>
  | EmailVariableInput<EmailVariableKey.Company>
  | EmailVariableInput<EmailVariableKey.EventStartDay>
  | EmailVariableInput<EmailVariableKey.EventEndDay>
  | EmailVariableInput<EmailVariableKey.EventEndMonth>
  | EmailVariableInput<EmailVariableKey.EventEndYear>
  | EmailVariableInput<EmailVariableKey.Speaker>
  | EmailVariableInput<EmailVariableKey.Member>
  | EmailVariableInput<EmailVariableKey.MemberEmail>
  | EmailVariableInput<EmailVariableKey.MemberPhoneNumber>
  | EmailVariableInput<EmailVariableKey.MemberTeam>
  | EmailVariableInput<EmailVariableKey.Paragraph>;

// Helper functions to create strongly typed variables
export const createEmailVariable = {
  edition: (value: number): EmailVariableInput<EmailVariableKey.Edition> => ({
    key: EmailVariableKey.Edition,
    value,
  }),

  editionOrdinal: (
    value: number,
  ): EmailVariableInput<EmailVariableKey.EditionOrdinal> => ({
    key: EmailVariableKey.EditionOrdinal,
    value,
  }),

  company: (value: Company): EmailVariableInput<EmailVariableKey.Company> => ({
    key: EmailVariableKey.Company,
    value,
  }),

  eventStartDay: (
    value: Date,
  ): EmailVariableInput<EmailVariableKey.EventStartDay> => ({
    key: EmailVariableKey.EventStartDay,
    value,
  }),

  eventEndDay: (
    value: Date,
  ): EmailVariableInput<EmailVariableKey.EventEndDay> => ({
    key: EmailVariableKey.EventEndDay,
    value,
  }),

  eventEndMonth: (
    value: Date,
  ): EmailVariableInput<EmailVariableKey.EventEndMonth> => ({
    key: EmailVariableKey.EventEndMonth,
    value,
  }),

  eventEndYear: (
    value: Date,
  ): EmailVariableInput<EmailVariableKey.EventEndYear> => ({
    key: EmailVariableKey.EventEndYear,
    value,
  }),

  speaker: (value: Speaker): EmailVariableInput<EmailVariableKey.Speaker> => ({
    key: EmailVariableKey.Speaker,
    value,
  }),

  member: (
    value: MemberWithContact,
  ): EmailVariableInput<EmailVariableKey.Member> => ({
    key: EmailVariableKey.Member,
    value,
  }),

  memberEmail: (
    value: MemberWithContact,
  ): EmailVariableInput<EmailVariableKey.MemberEmail> => ({
    key: EmailVariableKey.MemberEmail,
    value,
  }),

  memberPhoneNumber: (
    value: MemberWithContact,
  ): EmailVariableInput<EmailVariableKey.MemberPhoneNumber> => ({
    key: EmailVariableKey.MemberPhoneNumber,
    value,
  }),

  memberTeam: (
    value: AuthorizationCredentials,
  ): EmailVariableInput<EmailVariableKey.MemberTeam> => ({
    key: EmailVariableKey.MemberTeam,
    value,
  }),

  paragraph: (
    value: string,
  ): EmailVariableInput<EmailVariableKey.Paragraph> => ({
    key: EmailVariableKey.Paragraph,
    value,
  }),
};
