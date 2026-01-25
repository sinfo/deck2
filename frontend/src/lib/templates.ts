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
  COMPANIES_ADDITIONALINFO_EN = "COMPANIES_ADDITIONALINFO_EN",
  COMPANIES_ADDITIONALINFO_PT = "COMPANIES_ADDITIONALINFO_PT",
  COMPANIES_CVS_EN = "COMPANIES_CVS_EN",
  COMPANIES_CVS_PT = "COMPANIES_CVS_PT",
  COMPANIES_MISSINGINFO_EN = "COMPANIES_MISSINGINFO_EN",
  COMPANIES_MISSINGINFO_PT = "COMPANIES_MISSINGINFO_PT",
  COMPANIES_REQUESTPARK_EN = "COMPANIES_REQUESTPARK_EN",
  COMPANIES_REQUESTPARK_PT = "COMPANIES_REQUESTPARK_PT",
  COMPANIES_VEGAN_EN = "COMPANIES_VEGAN_EN",
  COMPANIES_VEGAN_PT = "COMPANIES_VEGAN_PT",
  COMPANIES_WAITINGLINE_EN = "COMPANIES_WAITINGLINE_EN",
  COMPANIES_WAITINGLINE_PT = "COMPANIES_WAITINGLINE_PT",
  SPEAKERS_EN = "SPEAKERS_EN",
  SPEAKERS_PT = "SPEAKERS_PT",
}

// 2. Set the template names here
export const templateHumanReadableNames: Record<EmailTemplate, string> = {
  [EmailTemplate.COMPANIES_EN]: "Companies Invitation - English",
  [EmailTemplate.COMPANIES_PT]: "Companies Invitation - Português",
  [EmailTemplate.COMPANIES_ADDITIONALINFO_EN]:
    "Companies Additional Info - English",
  [EmailTemplate.COMPANIES_ADDITIONALINFO_PT]:
    "Companies Additional Info - Português",
  [EmailTemplate.COMPANIES_CVS_EN]: "Companies CVs Download - English",
  [EmailTemplate.COMPANIES_CVS_PT]: "Companies CVs Download - Português",
  [EmailTemplate.COMPANIES_MISSINGINFO_EN]: "Companies Missing Info - English",
  [EmailTemplate.COMPANIES_MISSINGINFO_PT]:
    "Companies Missing Info - Português",
  [EmailTemplate.COMPANIES_REQUESTPARK_EN]:
    "Companies Parking Request - English",
  [EmailTemplate.COMPANIES_REQUESTPARK_PT]:
    "Companies Parking Request - Português",
  [EmailTemplate.COMPANIES_VEGAN_EN]: "Companies Vegan Info - English",
  [EmailTemplate.COMPANIES_VEGAN_PT]: "Companies Vegan Info - Português",
  [EmailTemplate.COMPANIES_WAITINGLINE_EN]: "Companies Waiting List - English",
  [EmailTemplate.COMPANIES_WAITINGLINE_PT]:
    "Companies Waiting List - Português",
  [EmailTemplate.SPEAKERS_EN]: "Speakers Invitation - English",
  [EmailTemplate.SPEAKERS_PT]: "Speakers Invitation - Português",
};

// 3. Set the template paths here
export const templatePaths: Record<EmailTemplate, string> = {
  [EmailTemplate.COMPANIES_EN]: "/companies/33-en.html",
  [EmailTemplate.COMPANIES_PT]: "/companies/33-pt.html",
  [EmailTemplate.COMPANIES_ADDITIONALINFO_EN]:
    "/companies/additionalinfo-en.html",
  [EmailTemplate.COMPANIES_ADDITIONALINFO_PT]:
    "/companies/additionalinfo-pt.html",
  [EmailTemplate.COMPANIES_CVS_EN]: "/companies/cvs-en.html",
  [EmailTemplate.COMPANIES_CVS_PT]: "/companies/cvs-pt.html",
  [EmailTemplate.COMPANIES_MISSINGINFO_EN]: "/companies/missinginfo-en.html",
  [EmailTemplate.COMPANIES_MISSINGINFO_PT]: "/companies/missinginfo-pt.html",
  [EmailTemplate.COMPANIES_REQUESTPARK_EN]: "/companies/requestpark-en.html",
  [EmailTemplate.COMPANIES_REQUESTPARK_PT]: "/companies/requestpark-pt.html",
  [EmailTemplate.COMPANIES_VEGAN_EN]: "/companies/vegan-en.html",
  [EmailTemplate.COMPANIES_VEGAN_PT]: "/companies/vegan-pt.html",
  [EmailTemplate.COMPANIES_WAITINGLINE_EN]: "/companies/waitingline-en.html",
  [EmailTemplate.COMPANIES_WAITINGLINE_PT]: "/companies/waitingline-pt.html",
  [EmailTemplate.SPEAKERS_EN]: "/speakers/33-en.html",
  [EmailTemplate.SPEAKERS_PT]: "/speakers/33-pt.html",
};

// 4. Set the company templates and the speaker templates
export const companyTemplates = [
  EmailTemplate.COMPANIES_EN,
  EmailTemplate.COMPANIES_PT,
  EmailTemplate.COMPANIES_ADDITIONALINFO_EN,
  EmailTemplate.COMPANIES_ADDITIONALINFO_PT,
  EmailTemplate.COMPANIES_CVS_EN,
  EmailTemplate.COMPANIES_CVS_PT,
  EmailTemplate.COMPANIES_MISSINGINFO_EN,
  EmailTemplate.COMPANIES_MISSINGINFO_PT,
  EmailTemplate.COMPANIES_REQUESTPARK_EN,
  EmailTemplate.COMPANIES_REQUESTPARK_PT,
  EmailTemplate.COMPANIES_VEGAN_EN,
  EmailTemplate.COMPANIES_VEGAN_PT,
  EmailTemplate.COMPANIES_WAITINGLINE_EN,
  EmailTemplate.COMPANIES_WAITINGLINE_PT,
];
export const speakerTemplates = [
  EmailTemplate.SPEAKERS_EN,
  EmailTemplate.SPEAKERS_PT,
];

// 5. Set the template categories (used on bulk form)
export enum EmailTemplateCategory {
  CONTACT_COMPANY = "CONTACT_COMPANY",
  CONTACT_COMPANY_ADDITIONALINFO = "CONTACT_COMPANY_ADDITIONALINFO",
  CONTACT_COMPANY_CVS = "CONTACT_COMPANY_CVS",
  CONTACT_COMPANY_MISSINGINFO = "CONTACT_COMPANY_MISSINGINFO",
  CONTACT_COMPANY_REQUESTPARK = "CONTACT_COMPANY_REQUESTPARK",
  CONTACT_COMPANY_VEGAN = "CONTACT_COMPANY_VEGAN",
  CONTACT_COMPANY_WAITINGLINE = "CONTACT_COMPANY_WAITINGLINE",
  CONTACT_SPEAKER = "CONTACT_SPEAKER",
}

export const templateCategoryHumanReadable: Record<
  EmailTemplateCategory,
  string
> = {
  [EmailTemplateCategory.CONTACT_COMPANY]: "Companies - Invitation",
  [EmailTemplateCategory.CONTACT_COMPANY_ADDITIONALINFO]:
    "Companies - Additional Info",
  [EmailTemplateCategory.CONTACT_COMPANY_CVS]: "Companies - CVs Download",
  [EmailTemplateCategory.CONTACT_COMPANY_MISSINGINFO]:
    "Companies - Missing Info",
  [EmailTemplateCategory.CONTACT_COMPANY_REQUESTPARK]:
    "Companies - Parking Request",
  [EmailTemplateCategory.CONTACT_COMPANY_VEGAN]: "Companies - Vegan Info",
  [EmailTemplateCategory.CONTACT_COMPANY_WAITINGLINE]:
    "Companies - Waiting List",
  [EmailTemplateCategory.CONTACT_SPEAKER]: "Speakers - Invitation",
};

export const companyTemplateCategories: EmailTemplateCategory[] = [
  EmailTemplateCategory.CONTACT_COMPANY,
  EmailTemplateCategory.CONTACT_COMPANY_ADDITIONALINFO,
  EmailTemplateCategory.CONTACT_COMPANY_CVS,
  EmailTemplateCategory.CONTACT_COMPANY_MISSINGINFO,
  EmailTemplateCategory.CONTACT_COMPANY_REQUESTPARK,
  EmailTemplateCategory.CONTACT_COMPANY_VEGAN,
  EmailTemplateCategory.CONTACT_COMPANY_WAITINGLINE,
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
  [EmailTemplateCategory.CONTACT_COMPANY_ADDITIONALINFO]: {
    [Language.ENGLISH]: EmailTemplate.COMPANIES_ADDITIONALINFO_EN,
    [Language.PORTUGUESE]: EmailTemplate.COMPANIES_ADDITIONALINFO_PT,
  },
  [EmailTemplateCategory.CONTACT_COMPANY_CVS]: {
    [Language.ENGLISH]: EmailTemplate.COMPANIES_CVS_EN,
    [Language.PORTUGUESE]: EmailTemplate.COMPANIES_CVS_PT,
  },
  [EmailTemplateCategory.CONTACT_COMPANY_MISSINGINFO]: {
    [Language.ENGLISH]: EmailTemplate.COMPANIES_MISSINGINFO_EN,
    [Language.PORTUGUESE]: EmailTemplate.COMPANIES_MISSINGINFO_PT,
  },
  [EmailTemplateCategory.CONTACT_COMPANY_REQUESTPARK]: {
    [Language.ENGLISH]: EmailTemplate.COMPANIES_REQUESTPARK_EN,
    [Language.PORTUGUESE]: EmailTemplate.COMPANIES_REQUESTPARK_PT,
  },
  [EmailTemplateCategory.CONTACT_COMPANY_VEGAN]: {
    [Language.ENGLISH]: EmailTemplate.COMPANIES_VEGAN_EN,
    [Language.PORTUGUESE]: EmailTemplate.COMPANIES_VEGAN_PT,
  },
  [EmailTemplateCategory.CONTACT_COMPANY_WAITINGLINE]: {
    [Language.ENGLISH]: EmailTemplate.COMPANIES_WAITINGLINE_EN,
    [Language.PORTUGUESE]: EmailTemplate.COMPANIES_WAITINGLINE_PT,
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
  NextEdition = "NextEdition", // next edition (current + 1)
  NextYear = "NextYear", // next year (current event year + 1)
  EventStartDay = "EventStartDay",
  EventEndDay = "EventEndDay",
  EventEndMonth = "EventEndMonth",
  EventEndYear = "EventEndYear",

  Company = "Company",
  ContactName = "ContactName", // contact name from company
  Package = "Package", // package name for waiting list emails

  // Boolean variables for conditional sections (for Missing Info template)
  NeedsContract = "NeedsContract",
  NeedsPayment = "NeedsPayment",
  NeedsSessionNames = "NeedsSessionNames",
  NeedsSessionInfo = "NeedsSessionInfo",

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
  [EmailVariableKey.NextEdition]: number;
  [EmailVariableKey.NextYear]: number;
  [EmailVariableKey.Company]: Company;
  [EmailVariableKey.ContactName]: string;
  [EmailVariableKey.Package]: string;
  [EmailVariableKey.NeedsContract]: boolean;
  [EmailVariableKey.NeedsPayment]: boolean;
  [EmailVariableKey.NeedsSessionNames]: boolean;
  [EmailVariableKey.NeedsSessionInfo]: boolean;
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

// 6.2 Define form fields for templates that need custom user input
export interface TemplateFormField {
  key: EmailVariableKey;
  label: string;
  type: "checkbox";
  defaultValue: boolean;
}

export const templateCategoryFormFields: Partial<
  Record<EmailTemplateCategory, TemplateFormField[]>
> = {
  [EmailTemplateCategory.CONTACT_COMPANY_MISSINGINFO]: [
    {
      key: EmailVariableKey.NeedsContract,
      label: "Needs to send participation contract",
      type: "checkbox",
      defaultValue: true,
    },
    {
      key: EmailVariableKey.NeedsPayment,
      label: "Needs to pay",
      type: "checkbox",
      defaultValue: true,
    },
    {
      key: EmailVariableKey.NeedsSessionNames,
      label: "Needs to send session names",
      type: "checkbox",
      defaultValue: true,
    },
    {
      key: EmailVariableKey.NeedsSessionInfo,
      label: "Needs to send session info (speaker name, position, abstract)",
      type: "checkbox",
      defaultValue: false,
    },
  ],
};

// 6.3 Update the variables of each entity (company/speaker)
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
  contactName?: string; // Optional contact name for company emails
  package?: string; // Optional package name for waiting list emails
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
    createEmailVariable.nextEdition(input.event.id + 1),
    createEmailVariable.nextYear(end.getFullYear() + 1),
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
    const companyVars = [...vars, createEmailVariable.company(input.company)];
    if (input.contactName) {
      companyVars.push(createEmailVariable.contactName(input.contactName));
    }
    if (input.package) {
      companyVars.push(createEmailVariable.package(input.package));
    }
    return companyVars;
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

    case EmailVariableKey.NextEdition: {
      // NextEdition is a number (current edition + 1)
      return variable.value.toString();
    }

    case EmailVariableKey.NextYear: {
      // NextYear is a number (current event year + 1)
      return variable.value.toString();
    }

    case EmailVariableKey.Company: {
      // Company is a Company object, return the name
      return variable.value.name;
    }

    case EmailVariableKey.ContactName: {
      // ContactName is a string
      return variable.value;
    }

    case EmailVariableKey.Package: {
      // Package is a string
      return variable.value;
    }

    case EmailVariableKey.NeedsContract:
    case EmailVariableKey.NeedsPayment:
    case EmailVariableKey.NeedsSessionNames:
    case EmailVariableKey.NeedsSessionInfo: {
      // Boolean variables - return empty string, they're handled by conditionals
      return variable.value ? "true" : "";
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

// Variables that use the first value from a list and need a warning
export interface FirstValueWarning {
  variableName: string;
  description: string;
  value: string | undefined;
}

/**
 * Get warnings for variables that use the first value from a list.
 * This helps users verify they're using the correct contact info.
 */
export const getFirstValueWarnings = (
  variables: AnyEmailVariableInput[],
): FirstValueWarning[] => {
  const warnings: FirstValueWarning[] = [];

  for (const variable of variables) {
    if (variable.key === EmailVariableKey.MemberEmail) {
      const email = variable.value.contactObject.mails?.[0]?.mail;
      if (email) {
        warnings.push({
          variableName: "Member Email",
          description: "Using first email from contact list",
          value: email,
        });
      }
    }

    if (variable.key === EmailVariableKey.MemberPhoneNumber) {
      const phone = variable.value.contactObject.phones?.[0]?.phone;
      if (phone) {
        warnings.push({
          variableName: "Member Phone",
          description: "Using first phone from contact list",
          value: phone,
        });
      }
    }
  }

  return warnings;
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
  | EmailVariableInput<EmailVariableKey.NextEdition>
  | EmailVariableInput<EmailVariableKey.NextYear>
  | EmailVariableInput<EmailVariableKey.Company>
  | EmailVariableInput<EmailVariableKey.ContactName>
  | EmailVariableInput<EmailVariableKey.Package>
  | EmailVariableInput<EmailVariableKey.NeedsContract>
  | EmailVariableInput<EmailVariableKey.NeedsPayment>
  | EmailVariableInput<EmailVariableKey.NeedsSessionNames>
  | EmailVariableInput<EmailVariableKey.NeedsSessionInfo>
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

  nextEdition: (
    value: number,
  ): EmailVariableInput<EmailVariableKey.NextEdition> => ({
    key: EmailVariableKey.NextEdition,
    value,
  }),

  nextYear: (value: number): EmailVariableInput<EmailVariableKey.NextYear> => ({
    key: EmailVariableKey.NextYear,
    value,
  }),

  company: (value: Company): EmailVariableInput<EmailVariableKey.Company> => ({
    key: EmailVariableKey.Company,
    value,
  }),

  contactName: (
    value: string,
  ): EmailVariableInput<EmailVariableKey.ContactName> => ({
    key: EmailVariableKey.ContactName,
    value,
  }),

  package: (value: string): EmailVariableInput<EmailVariableKey.Package> => ({
    key: EmailVariableKey.Package,
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

  needsContract: (
    value: boolean,
  ): EmailVariableInput<EmailVariableKey.NeedsContract> => ({
    key: EmailVariableKey.NeedsContract,
    value,
  }),

  needsPayment: (
    value: boolean,
  ): EmailVariableInput<EmailVariableKey.NeedsPayment> => ({
    key: EmailVariableKey.NeedsPayment,
    value,
  }),

  needsSessionNames: (
    value: boolean,
  ): EmailVariableInput<EmailVariableKey.NeedsSessionNames> => ({
    key: EmailVariableKey.NeedsSessionNames,
    value,
  }),

  needsSessionInfo: (
    value: boolean,
  ): EmailVariableInput<EmailVariableKey.NeedsSessionInfo> => ({
    key: EmailVariableKey.NeedsSessionInfo,
    value,
  }),
};
