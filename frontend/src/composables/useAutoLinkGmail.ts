import { ref } from "vue";
import { useQueryCache } from "@pinia/colada";
import { useAuthStore } from "@/stores/auth";
import { useToast } from "@/lib/toast";
import { useGoogleAuth } from "./useGoogleAuth";
import { useGmailMessages } from "./useGmailMessages";
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

export type EntityAutoLinkStatus =
  | "SUCCESS"
  | "ALREADY_LINKED"
  | "NOT_FOUND"
  | "ERROR";

export interface EntityLinkResult {
  entityId: string;
  entityName: string;
  entityType: "company" | "speaker";
  status: EntityAutoLinkStatus;
  participationStatus?: ParticipationStatus;
  linkedThreadsCount: number;
  newlyLinkedCount: number;
  threadIds: string[];
  errorMessage?: string;
  searchQueryUsed?: string;
}

export const CONTACTED_PARTICIPATION_STATUSES: readonly ParticipationStatus[] =
  [
    "CONTACTED",
    "IN_CONVERSATIONS",
    "ACCEPTED",
    "REJECTED",
    "GIVEN_UP",
    "ANNOUNCED",
  ] as const;

export const isContactedParticipationStatus = (
  status?: ParticipationStatus,
): boolean => {
  return status ? CONTACTED_PARTICIPATION_STATUSES.includes(status) : false;
};

interface EntityProcessConfig {
  id: string;
  name: string;
  type: "company" | "speaker";
  existingThreads: string[];
  participationStatus?: ParticipationStatus;
  fetchEmails: () => Promise<string[]>;
  updateThreadIds: (ids: string[]) => Promise<unknown>;
  syncMessages: (messages: GmailMessageData[]) => Promise<unknown>;
}

// Regex matching reply headers, forwarded blocks, and signatures to strip quoted email history
const QUOTE_HEADER_REGEX =
  /^(On\s+.+\s+wrote:?|On\s+\w{3},?\s+\w{3}\s+\d{1,2}|On\s+\w{3},?\s+\d{1,2}\s+\w{3}|On\s+\d{1,2}\s+\w{3}\s+\d{4}|.*wrote:\s*$|>|-{3,}\s*Original Message\s*-{3,}|_{3,}|From:.*Sent:.*To:|--\s*Forwarded message\s*--|<[^>]+@[^>]+>\s*wrote:?|[^>]*<\s*$|[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+>\s*wrote:?)/i;

/**
 * Strips HTML tags and removes quoted email replies/history
 */
const cleanMessageBody = (body: string): string => {
  if (!body) return "";
  let text = body;
  if (text.includes("<") && text.includes(">")) {
    try {
      const doc = new DOMParser().parseFromString(text, "text/html");
      doc.querySelectorAll("script, style").forEach((el) => el.remove());
      doc.querySelectorAll("br").forEach((el) => el.replaceWith("\n"));
      doc.querySelectorAll("p, div, tr, li").forEach((el) => {
        el.prepend(document.createTextNode("\n"));
        el.append(document.createTextNode("\n"));
      });
      text = doc.body.textContent || "";
    } catch {
      // Fall back to raw text if HTML parsing fails
    }
  }

  // Normalize multi-line quote headers (e.g. "On Fri, 16 Jan 2026 at 09:40, Name <\nemail@example.com> wrote:")
  const normalizedBody = text.replace(
    /^(On\s+\w{3},\s+\d{1,2}\s+\w{3}\s+\d{4}\s+at\s+\d{1,2}:\d{2},\s+[^<]+)<\s*\n\s*([^>]+@[^>]+)>\s*wrote:/gim,
    "$1<$2> wrote:",
  );

  const lines = normalizedBody.split("\n");
  const cleanedLines: string[] = [];
  for (const line of lines) {
    if (QUOTE_HEADER_REGEX.test(line)) {
      break;
    }
    cleanedLines.push(line);
  }

  const result = cleanedLines.length > 0 ? cleanedLines.join("\n") : text;

  return result
    .replace(/\r\n/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .replace(/[ \t]+/g, " ")
    .replace(/^ +/gm, "")
    .replace(/ +$/gm, "")
    .trim();
};

const formatEmailAddress = (addr: string): string => {
  if (!addr) return "";
  return addr.replace(/"/g, "").trim();
};

const parseDateToIso = (dateStr: string, internalDate: string): string => {
  if (dateStr) {
    try {
      return new Date(dateStr).toISOString();
    } catch {
      // Fallback to internalDate below
    }
  }
  return new Date(parseInt(internalDate, 10)).toISOString();
};

const extractMailsFromList = (mails?: { mail?: string }[]): string[] => {
  return (mails?.map((m) => m.mail?.trim()).filter(Boolean) as string[]) ?? [];
};

const extractEmailAddressesFromHeader = (header?: string): string[] => {
  if (!header) return [];
  const matches = header.match(
    /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g,
  );
  return matches ? matches.map((m) => m.toLowerCase()) : [];
};

const getGmailThreadIds = (
  entity: {
    participations?: { event: number; gmailThreadIds?: string[] }[];
  },
  eventId: number,
): string[] => {
  return (
    entity.participations?.find((p) => p.event === eventId)?.gmailThreadIds ||
    []
  );
};

const fetchCompanyEmails = async (companyId: string): Promise<string[]> => {
  try {
    const repsRes = await getCompanyRepresentatives(companyId);
    return (repsRes.data || []).flatMap((rep) =>
      extractMailsFromList(rep.contact?.mails),
    );
  } catch {
    return [];
  }
};

const fetchSpeakerEmails = async (speakerId: string): Promise<string[]> => {
  try {
    const detailRes = await getSpeakerById(speakerId);
    return extractMailsFromList(detailRes.data?.contactObject?.mails);
  } catch {
    return [];
  }
};

// Shared singleton state across all composable consumers
const isAutoLinking = ref(false);
const hasScanned = ref(false);
const progressPercent = ref(0);
const currentProcessingEntity = ref<string>("");
const results = ref<EntityLinkResult[]>([]);
const error = ref<string | null>(null);

// Shared in-flight sync promise to coordinate concurrent calls (e.g. from Entry.vue and SettingsView.vue)
let activeSyncPromise: Promise<EntityLinkResult[]> | null = null;
let lastWarnTimestamp = 0;

export const useAutoLinkGmail = () => {
  const authStore = useAuthStore();
  const queryCache = useQueryCache();
  const { toast } = useToast();
  const { requestGoogleToken } = useGoogleAuth();
  const gmailComposable = useGmailMessages();

  const ensureValidGoogleToken = async (): Promise<boolean> => {
    if (!authStore.isGoogleAuthenticated) return false;
    if (authStore.hasValidGoogleToken) return true;
    return await requestGoogleToken({ silent: true });
  };

  /**
   * Filter results to find contacted entities without linked threads
   */
  const getUnlinkedContacted = (
    resultsList: EntityLinkResult[] = results.value,
  ): EntityLinkResult[] => {
    return resultsList.filter(
      (r) =>
        r.status === "NOT_FOUND" &&
        isContactedParticipationStatus(r.participationStatus),
    );
  };

  /**
   * Trigger a toast warning if any contacted entities are unlinked
   */
  const warnUnlinkedContacted = (
    resultsList: EntityLinkResult[] = results.value,
  ) => {
    const unlinked = getUnlinkedContacted(resultsList);
    if (unlinked.length === 0) return;

    const now = Date.now();
    if (now - lastWarnTimestamp < 5000) return;
    lastWarnTimestamp = now;

    const names = unlinked
      .slice(0, 3)
      .map((r) => r.entityName)
      .join(", ");
    const extra = unlinked.length > 3 ? ` and ${unlinked.length - 3} more` : "";

    toast.warning({
      title: "Gmail Threads Not Found",
      description: `Could not find Gmail threads for ${unlinked.length} contacted entity/entities: ${names}${extra}.`,
    });
  };

  /**
   * Fetch and prepare Gmail messages for backend sync
   */
  const fetchMessagesForThreads = async (
    threadIds: string[],
  ): Promise<GmailMessageData[]> => {
    if (!threadIds || threadIds.length === 0) return [];
    if (!(await ensureValidGoogleToken())) return [];

    const allMessages: GmailMessageData[] = [];
    const userEmail = authStore.sinfoEmail || "";

    for (const threadId of threadIds) {
      let threadMessages = await gmailComposable.getMessagesByThreadId(
        threadId,
        { format: "full" },
      );

      if (gmailComposable.needsReauth.value) {
        const authed = await requestGoogleToken();
        if (!authed) break;
        threadMessages = await gmailComposable.getMessagesByThreadId(threadId, {
          format: "full",
        });
      }

      for (const msg of threadMessages || []) {
        const from = gmailComposable.getHeaderValue(msg, "From") || "Unknown";
        const to = gmailComposable.getHeaderValue(msg, "To") || "";
        const subject =
          gmailComposable.getHeaderValue(msg, "Subject") || "(No subject)";
        const dateStr = gmailComposable.getHeaderValue(msg, "Date") || "";
        const isoDate = parseDateToIso(dateStr, msg.internalDate);

        let body =
          gmailComposable.getMessageBody(msg, false) || msg.snippet || "";
        body = cleanMessageBody(body);

        const isOutgoing = Boolean(
          from.toLowerCase().includes("@sinfo.org") ||
            (userEmail && from.toLowerCase().includes(userEmail.toLowerCase())),
        );

        allMessages.push({
          messageId: msg.id,
          threadId: msg.threadId,
          subject,
          from: formatEmailAddress(from),
          to: formatEmailAddress(to),
          date: isoDate,
          body,
          isOutgoing,
        });
      }
    }

    return allMessages;
  };

  /**
   * Internal implementation of entity scanning and Gmail thread linking
   */
  const executeAutoLinkEntities = async (
    eventId: number,
    options: { forceReScan?: boolean; onlyMyResponsibilities?: boolean } = {},
  ): Promise<EntityLinkResult[]> => {
    isAutoLinking.value = true;
    hasScanned.value = false;
    error.value = null;
    progressPercent.value = 0;
    results.value = [];

    try {
      let companies: Company[] = [];
      let speakers: Speaker[] = [];

      // By default only sync entities assigned to current user to avoid cross-member pollution
      const onlyMy = options.onlyMyResponsibilities !== false;
      if (onlyMy) {
        try {
          const myResp = await getMyResponsibilities({ event: eventId });
          companies = myResp.data?.companies || [];
          speakers = myResp.data?.speakers || [];
        } catch (err) {
          console.error("Failed to fetch my responsibilities:", err);
          error.value =
            err instanceof Error
              ? err.message
              : "Failed to fetch assigned companies and speakers";
          return [];
        }
      } else {
        const [companiesRes, speakersRes] = await Promise.all([
          getAllCompanies({ event: eventId }),
          getAllSpeakers({ event: eventId }),
        ]);
        companies = companiesRes.data || [];
        speakers = speakersRes.data || [];
      }

      const totalEntities = companies.length + speakers.length;
      if (totalEntities === 0) {
        return [];
      }

      let processedCount = 0;

      const processEntity = async (target: EntityProcessConfig) => {
        currentProcessingEntity.value = target.name;
        processedCount++;
        progressPercent.value = Math.round(
          (processedCount / totalEntities) * 100,
        );

        const existingThreads = target.existingThreads;

        const syncMessagesForThreads = async (threadIds: string[]) => {
          if (threadIds.length === 0) return;
          const messagesToSync = await fetchMessagesForThreads(threadIds);
          if (messagesToSync.length > 0) {
            await target.syncMessages(messagesToSync);
          }
        };

        if (existingThreads.length > 0 && !options.forceReScan) {
          try {
            await syncMessagesForThreads(existingThreads);
          } catch (syncErr) {
            console.error(
              `Failed to sync existing messages for ${target.type} ${target.name}:`,
              syncErr,
            );
          }

          results.value.push({
            entityId: target.id,
            entityName: target.name,
            entityType: target.type,
            status: "ALREADY_LINKED",
            participationStatus: target.participationStatus,
            linkedThreadsCount: existingThreads.length,
            newlyLinkedCount: 0,
            threadIds: existingThreads,
            searchQueryUsed: target.name,
          });
          return;
        }

        const emails = await target.fetchEmails();
        const query =
          emails.length > 0
            ? emails.map((e) => `from:${e} OR to:${e}`).join(" OR ")
            : `"${target.name}"`;

        try {
          let threadListRes = await gmailComposable.listThreads({
            q: query,
            maxResults: 10,
          });

          if (gmailComposable.needsReauth.value) {
            const authed = await requestGoogleToken();
            if (!authed) throw new Error("Google authentication failed");
            threadListRes = await gmailComposable.listThreads({
              q: query,
              maxResults: 10,
            });
          }

          const matchedThreads = threadListRes?.threads || [];
          const matchedThreadIds = matchedThreads.map((t) => t.id);

          if (matchedThreadIds.length === 0) {
            results.value.push({
              entityId: target.id,
              entityName: target.name,
              entityType: target.type,
              status: "NOT_FOUND",
              participationStatus: target.participationStatus,
              linkedThreadsCount: 0,
              newlyLinkedCount: 0,
              threadIds: [],
              searchQueryUsed: query,
            });
            return;
          }

          const newThreadIds = Array.from(
            new Set([...existingThreads, ...matchedThreadIds]),
          );
          const newlyAdded = newThreadIds.filter(
            (id) => !existingThreads.includes(id),
          );

          if (newlyAdded.length > 0) {
            await target.updateThreadIds(newThreadIds);
          }

          await syncMessagesForThreads(newThreadIds);

          results.value.push({
            entityId: target.id,
            entityName: target.name,
            entityType: target.type,
            status: "SUCCESS",
            participationStatus: target.participationStatus,
            linkedThreadsCount: newThreadIds.length,
            newlyLinkedCount: newlyAdded.length,
            threadIds: newThreadIds,
            searchQueryUsed: query,
          });
        } catch (err) {
          results.value.push({
            entityId: target.id,
            entityName: target.name,
            entityType: target.type,
            status: "ERROR",
            participationStatus: target.participationStatus,
            linkedThreadsCount: existingThreads.length,
            newlyLinkedCount: 0,
            threadIds: existingThreads,
            errorMessage:
              err instanceof Error ? err.message : "Failed to search Gmail",
            searchQueryUsed: query,
          });
        }
      };

      for (const company of companies) {
        const compParticipation = company.participations?.find(
          (p) => p.event === eventId,
        );
        await processEntity({
          id: company.id,
          name: company.name,
          type: "company",
          existingThreads: getGmailThreadIds(company, eventId),
          participationStatus: compParticipation?.status,
          fetchEmails: () => fetchCompanyEmails(company.id),
          updateThreadIds: (ids) =>
            updateCompanyGmailThreadIds(company.id, ids),
          syncMessages: (msgs) => syncCompanyGmailMessages(company.id, msgs),
        });
      }

      for (const speaker of speakers) {
        const speakerParticipation = speaker.participations?.find(
          (p) => p.event === eventId,
        );
        await processEntity({
          id: speaker.id,
          name: speaker.name,
          type: "speaker",
          existingThreads: getGmailThreadIds(speaker, eventId),
          participationStatus: speakerParticipation?.status,
          fetchEmails: () => fetchSpeakerEmails(speaker.id),
          updateThreadIds: (ids) =>
            updateSpeakerGmailThreadIds(speaker.id, ids),
          syncMessages: (msgs) => syncSpeakerGmailMessages(speaker.id, msgs),
        });
      }

      localStorage.setItem(
        `gmail_last_sync_timestamp_${eventId}`,
        String(Date.now()),
      );

      queryCache.invalidateQueries({ key: ["company-communications"] });
      queryCache.invalidateQueries({ key: ["speaker-communications"] });
      queryCache.invalidateQueries({ key: ["my-responsibilities"] });

      return results.value;
    } catch (err) {
      error.value =
        err instanceof Error
          ? err.message
          : "An error occurred during auto-linking";
      return results.value;
    } finally {
      isAutoLinking.value = false;
      hasScanned.value = true;
    }
  };

  /**
   * Scans all assigned entities and links their Gmail threads (initial setup / manual re-scan)
   */
  const autoLinkEventEntities = async (
    eventId: number,
    options: { forceReScan?: boolean; onlyMyResponsibilities?: boolean } = {},
  ): Promise<EntityLinkResult[]> => {
    if (activeSyncPromise) {
      return activeSyncPromise;
    }

    if (!(await ensureValidGoogleToken())) {
      return [];
    }

    const promise = (async () => {
      try {
        return await executeAutoLinkEntities(eventId, options);
      } finally {
        activeSyncPromise = null;
      }
    })();

    activeSyncPromise = promise;
    return await promise;
  };

  /**
   * Delta sync: checks only threads updated since last sync, updating only entities with new messages
   */
  const syncRecentGmailUpdates = async (
    eventId: number,
  ): Promise<EntityLinkResult[]> => {
    if (activeSyncPromise) {
      return activeSyncPromise;
    }

    if (!(await ensureValidGoogleToken())) {
      return [];
    }

    const promise = (async () => {
      try {
        const storageKey = `gmail_last_sync_timestamp_${eventId}`;
        const lastSyncTimeStr = localStorage.getItem(storageKey);
        const lastSyncTime = lastSyncTimeStr ? Number(lastSyncTimeStr) : null;

        // Fallback: full scan on first run
        if (!lastSyncTime || isNaN(lastSyncTime)) {
          const initialResults = await executeAutoLinkEntities(eventId, {
            onlyMyResponsibilities: true,
          });
          localStorage.setItem(storageKey, String(Date.now()));
          return initialResults;
        }

        isAutoLinking.value = true;
        error.value = null;

        try {
          // 3m margin for clock drift and delivery delay
          const afterEpochSec = Math.max(
            0,
            Math.floor(lastSyncTime / 1000) - 180,
          );
          const query = `after:${afterEpochSec}`;

          let recentThreadsRes = await gmailComposable.listThreads({
            q: query,
            maxResults: 20,
          });

          if (gmailComposable.needsReauth.value) {
            const authed = await requestGoogleToken();
            if (!authed) throw new Error("Google authentication failed");
            recentThreadsRes = await gmailComposable.listThreads({
              q: query,
              maxResults: 20,
            });
          }

          const recentThreads = recentThreadsRes?.threads || [];

          // No new threads -> exit immediately
          if (recentThreads.length === 0) {
            localStorage.setItem(storageKey, String(Date.now()));
            return [];
          }

          // Fetch messages only for recent threads
          const recentThreadIds = recentThreads.map((t) => t.id);
          const recentMessages = await fetchMessagesForThreads(recentThreadIds);

          if (recentMessages.length === 0) {
            localStorage.setItem(storageKey, String(Date.now()));
            return [];
          }

          const myResp = await getMyResponsibilities({ event: eventId });
          const companies = myResp.data?.companies || [];
          const speakers = myResp.data?.speakers || [];

          // Maps for fast matching
          const threadToCompany = new Map<string, Company>();
          const threadToSpeaker = new Map<string, Speaker>();
          const emailToCompany = new Map<string, Company>();
          const emailToSpeaker = new Map<string, Speaker>();

          for (const company of companies) {
            for (const tid of getGmailThreadIds(company, eventId)) {
              threadToCompany.set(tid, company);
            }
          }

          for (const speaker of speakers) {
            for (const tid of getGmailThreadIds(speaker, eventId)) {
              threadToSpeaker.set(tid, speaker);
            }
          }

          // Preload contact emails for assigned entities
          await Promise.all([
            ...companies.map(async (company) => {
              const mails = await fetchCompanyEmails(company.id);
              for (const mail of mails) {
                emailToCompany.set(mail.toLowerCase(), company);
              }
            }),
            ...speakers.map(async (speaker) => {
              const mails = await fetchSpeakerEmails(speaker.id);
              for (const mail of mails) {
                emailToSpeaker.set(mail.toLowerCase(), speaker);
              }
            }),
          ]);

          // Group messages by matched entity
          const companyPayloads = new Map<
            string,
            {
              entity: Company;
              messages: GmailMessageData[];
              threadIds: Set<string>;
            }
          >();
          const speakerPayloads = new Map<
            string,
            {
              entity: Speaker;
              messages: GmailMessageData[];
              threadIds: Set<string>;
            }
          >();

          const addToPayload = <T extends Company | Speaker>(
            map: Map<
              string,
              {
                entity: T;
                messages: GmailMessageData[];
                threadIds: Set<string>;
              }
            >,
            id: string,
            entity: T,
            msg: GmailMessageData,
          ) => {
            const item = map.get(id) || {
              entity,
              messages: [],
              threadIds: new Set<string>(),
            };
            item.messages.push(msg);
            item.threadIds.add(msg.threadId);
            map.set(id, item);
          };

          for (const msg of recentMessages) {
            let matchedCompany = threadToCompany.get(msg.threadId);
            let matchedSpeaker = threadToSpeaker.get(msg.threadId);

            if (!matchedCompany && !matchedSpeaker) {
              const emails = [
                ...extractEmailAddressesFromHeader(msg.from),
                ...extractEmailAddressesFromHeader(msg.to),
              ];
              for (const email of emails) {
                if (emailToCompany.has(email)) {
                  matchedCompany = emailToCompany.get(email);
                  break;
                }
                if (emailToSpeaker.has(email)) {
                  matchedSpeaker = emailToSpeaker.get(email);
                  break;
                }
              }
            }

            if (matchedCompany) {
              addToPayload(
                companyPayloads,
                matchedCompany.id,
                matchedCompany,
                msg,
              );
            } else if (matchedSpeaker) {
              addToPayload(
                speakerPayloads,
                matchedSpeaker.id,
                matchedSpeaker,
                msg,
              );
            }
          }

          const updatedResults: EntityLinkResult[] = [];

          const persistEntityUpdates = async (
            type: "company" | "speaker",
            entity: Company | Speaker,
            messages: GmailMessageData[],
            newThreadIds: Set<string>,
            updateThreadIdsFn: (id: string, ids: string[]) => Promise<unknown>,
            syncMessagesFn: (
              id: string,
              msgs: GmailMessageData[],
            ) => Promise<unknown>,
          ): Promise<EntityLinkResult> => {
            const existing = getGmailThreadIds(entity, eventId);
            const combined = Array.from(
              new Set([...existing, ...newThreadIds]),
            );
            if (combined.length > existing.length) {
              await updateThreadIdsFn(entity.id, combined);
            }
            if (messages.length > 0) {
              await syncMessagesFn(entity.id, messages);
            }
            return {
              entityId: entity.id,
              entityName: entity.name,
              entityType: type,
              status: "SUCCESS",
              participationStatus: entity.participations?.find(
                (p) => p.event === eventId,
              )?.status,
              linkedThreadsCount: combined.length,
              newlyLinkedCount: combined.length - existing.length,
              threadIds: combined,
            };
          };

          for (const item of companyPayloads.values()) {
            updatedResults.push(
              await persistEntityUpdates(
                "company",
                item.entity,
                item.messages,
                item.threadIds,
                updateCompanyGmailThreadIds,
                syncCompanyGmailMessages,
              ),
            );
          }

          for (const item of speakerPayloads.values()) {
            updatedResults.push(
              await persistEntityUpdates(
                "speaker",
                item.entity,
                item.messages,
                item.threadIds,
                updateSpeakerGmailThreadIds,
                syncSpeakerGmailMessages,
              ),
            );
          }

          localStorage.setItem(storageKey, String(Date.now()));

          if (updatedResults.length > 0) {
            queryCache.invalidateQueries({ key: ["company-communications"] });
            queryCache.invalidateQueries({ key: ["speaker-communications"] });
            queryCache.invalidateQueries({ key: ["my-responsibilities"] });
          }

          return updatedResults;
        } catch (err) {
          console.error("Delta sync error:", err);
          error.value =
            err instanceof Error ? err.message : "Delta sync failed";
          return [];
        } finally {
          isAutoLinking.value = false;
        }
      } finally {
        activeSyncPromise = null;
      }
    })();

    activeSyncPromise = promise;
    return await promise;
  };

  return {
    isAutoLinking,
    hasScanned,
    progressPercent,
    currentProcessingEntity,
    results,
    error,
    getUnlinkedContacted,
    warnUnlinkedContacted,
    autoLinkEventEntities,
    syncRecentGmailUpdates,
    fetchMessagesForThreads,
  };
};
