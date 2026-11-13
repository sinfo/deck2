import {
  getAllCompanies,
  getCompanyRepresentatives,
  updateCompanyGmailThreadIds,
  syncCompanyGmailMessages,
  type GmailMessageData,
} from "@/api/companies";
import {
  getAllSpeakers,
  getSpeakerById,
  updateSpeakerGmailThreadIds,
  syncSpeakerGmailMessages,
} from "@/api/speakers";
import { getMyResponsibilities } from "@/api/me";
import type { Company } from "@/dto/companies";
import type { Speaker } from "@/dto/speakers";
import type { ParticipationStatus } from "@/dto";
import type { GmailMessage } from "../useGmailMessages";

export type EntityType = "company" | "speaker";
export type EntityAutoLinkStatus =
  | "SUCCESS"
  | "ALREADY_LINKED"
  | "NOT_FOUND"
  | "ERROR";

export interface EntityLinkResult {
  entityId: string;
  entityName: string;
  entityType: EntityType;
  status: EntityAutoLinkStatus;
  participationStatus?: ParticipationStatus;
  linkedThreadsCount: number;
  newlyLinkedCount: number;
  threadIds: string[];
  errorMessage?: string;
  searchQueryUsed?: string;
}

export type SyncResult<T> =
  | { ok: true; value: T }
  | { ok: false; error: string };

export const success = <T>(value: T): SyncResult<T> => ({ ok: true, value });
export const failure = <T>(error: string): SyncResult<T> => ({
  ok: false,
  error,
});
export const errorMessage = (error: unknown): string =>
  error instanceof Error ? error.message : String(error);

export interface GmailEntity {
  id: string;
  name: string;
  type: EntityType;
  existingThreads: string[];
  participationStatus?: ParticipationStatus;
  fetchEmails: () => Promise<string[]>;
  updateThreadIds: (ids: string[]) => Promise<unknown>;
  syncMessages: (messages: GmailMessageData[]) => Promise<unknown>;
}

const emailsFromContacts = (mails?: { mail?: string }[]): string[] =>
  mails?.flatMap(({ mail }) => (mail?.trim() ? [mail.trim()] : [])) ?? [];

const gmailThreadIds = (entity: Company | Speaker, eventId: number): string[] =>
  entity.participations?.find(
    (participation) => participation.event === eventId,
  )?.gmailThreadIds ?? [];

// All API differences between companies and speakers stay in one place.
export const loadGmailEntities = async (
  eventId: number,
  onlyMyResponsibilities: boolean,
): Promise<SyncResult<GmailEntity[]>> => {
  try {
    let companies: Company[];
    let speakers: Speaker[];

    if (onlyMyResponsibilities) {
      const response = await getMyResponsibilities({ event: eventId });
      companies = response.data?.companies ?? [];
      speakers = response.data?.speakers ?? [];
    } else {
      const [companyResponse, speakerResponse] = await Promise.all([
        getAllCompanies({ event: eventId }),
        getAllSpeakers({ event: eventId }),
      ]);
      companies = companyResponse.data ?? [];
      speakers = speakerResponse.data ?? [];
    }

    return success([
      ...companies.map(
        (company): GmailEntity => ({
          id: company.id,
          name: company.name,
          type: "company",
          existingThreads: gmailThreadIds(company, eventId),
          participationStatus: company.participations?.find(
            (participation) => participation.event === eventId,
          )?.status,
          fetchEmails: async () => {
            const response = await getCompanyRepresentatives(company.id);
            return (response.data ?? []).flatMap((representative) =>
              emailsFromContacts(representative.contact?.mails),
            );
          },
          updateThreadIds: (ids) =>
            updateCompanyGmailThreadIds(company.id, ids, eventId),
          syncMessages: (messages) =>
            syncCompanyGmailMessages(company.id, messages, eventId),
        }),
      ),
      ...speakers.map(
        (speaker): GmailEntity => ({
          id: speaker.id,
          name: speaker.name,
          type: "speaker",
          existingThreads: gmailThreadIds(speaker, eventId),
          participationStatus: speaker.participations?.find(
            (participation) => participation.event === eventId,
          )?.status,
          fetchEmails: async () => {
            const response = await getSpeakerById(speaker.id);
            return emailsFromContacts(response.data?.contactObject?.mails);
          },
          updateThreadIds: (ids) =>
            updateSpeakerGmailThreadIds(speaker.id, ids, eventId),
          syncMessages: (messages) =>
            syncSpeakerGmailMessages(speaker.id, messages, eventId),
        }),
      ),
    ]);
  } catch (error) {
    return failure(errorMessage(error));
  }
};

export const entityResult = (
  entity: GmailEntity,
  status: EntityAutoLinkStatus,
  threadIds: string[],
  newlyLinkedCount = 0,
  details: Pick<EntityLinkResult, "errorMessage" | "searchQueryUsed"> = {},
): EntityLinkResult => ({
  entityId: entity.id,
  entityName: entity.name,
  entityType: entity.type,
  status,
  participationStatus: entity.participationStatus,
  linkedThreadsCount: threadIds.length,
  newlyLinkedCount,
  threadIds,
  ...details,
});

export const emailsInHeader = (header: string): string[] =>
  (header.match(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g) ?? []).map(
    (email) => email.toLowerCase(),
  );

// Remove quoted replies so a Gmail thread does not repeat the entire email history.
const QUOTE_HEADER_REGEX =
  /^(On\s+.+\s+wrote:?|On\s+\w{3},?\s+\w{3}\s+\d{1,2}|On\s+\w{3},?\s+\d{1,2}\s+\w{3}|On\s+\d{1,2}\s+\w{3}\s+\d{4}|.*wrote:\s*$|>|-{3,}\s*Original Message\s*-{3,}|_{3,}|From:.*Sent:.*To:|--\s*Forwarded message\s*--|<[^>]+@[^>]+>\s*wrote:?|[^>]*<\s*$|[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+>\s*wrote:?)/i;

const cleanMessageBody = (body: string): string => {
  let text = body;
  if (text.includes("<") && text.includes(">")) {
    const doc = new DOMParser().parseFromString(text, "text/html");
    doc
      .querySelectorAll("script, style")
      .forEach((element) => element.remove());
    doc.querySelectorAll("br").forEach((element) => element.replaceWith("\n"));
    doc.querySelectorAll("p, div, tr, li").forEach((element) => {
      element.prepend(document.createTextNode("\n"));
      element.append(document.createTextNode("\n"));
    });
    text = doc.body.textContent ?? "";
  }

  const normalized = text.replace(
    /^(On\s+\w{3},\s+\d{1,2}\s+\w{3}\s+\d{4}\s+at\s+\d{1,2}:\d{2},\s+[^<]+)<\s*\n\s*([^>]+@[^>]+)>\s*wrote:/gim,
    "$1<$2> wrote:",
  );
  const lines: string[] = [];
  for (const line of normalized.split("\n")) {
    if (QUOTE_HEADER_REGEX.test(line)) break;
    lines.push(line);
  }

  return (lines.length ? lines.join("\n") : text)
    .replace(/\r\n/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .replace(/[ \t]+/g, " ")
    .replace(/^ +/gm, "")
    .replace(/ +$/gm, "")
    .trim();
};

const isoDate = (dateHeader: string, internalDate: string): string => {
  const headerDate = new Date(dateHeader);
  const fallbackDate = new Date(Number(internalDate));
  const date = Number.isNaN(headerDate.getTime()) ? fallbackDate : headerDate;
  return Number.isNaN(date.getTime()) ? "" : date.toISOString();
};

export const prepareGmailMessage = (
  message: GmailMessage,
  ownEmail: string,
  getHeader: (message: GmailMessage, name: string) => string | undefined,
  getBody: (message: GmailMessage, preferHtml: boolean) => string | null,
): GmailMessageData => {
  const from = getHeader(message, "From") ?? "Unknown";
  const to = getHeader(message, "To") ?? "";
  const subject = getHeader(message, "Subject") ?? "(No subject)";
  const date = getHeader(message, "Date") ?? "";

  return {
    messageId: message.id,
    threadId: message.threadId,
    subject,
    from: from.replace(/"/g, "").trim(),
    to: to.replace(/"/g, "").trim(),
    date: isoDate(date, message.internalDate),
    body: cleanMessageBody(getBody(message, false) ?? message.snippet ?? ""),
    isOutgoing:
      from.toLowerCase().includes("@sinfo.org") ||
      Boolean(ownEmail && from.toLowerCase().includes(ownEmail.toLowerCase())),
  };
};
