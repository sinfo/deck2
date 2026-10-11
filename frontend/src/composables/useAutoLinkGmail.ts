import { ref } from "vue";
import { useAuthStore } from "@/stores/auth";
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
  linkedThreadsCount: number;
  newlyLinkedCount: number;
  threadIds: string[];
  errorMessage?: string;
  searchQueryUsed?: string;
}

interface EntityProcessConfig {
  id: string;
  name: string;
  type: "company" | "speaker";
  existingThreads: string[];
  fetchEmails: () => Promise<string[]>;
  updateThreadIds: (ids: string[]) => Promise<unknown>;
  syncMessages: (messages: GmailMessageData[]) => Promise<unknown>;
}

export const useAutoLinkGmail = () => {
  const authStore = useAuthStore();
  const { requestGoogleToken } = useGoogleAuth();
  const gmailComposable = useGmailMessages();

  const isAutoLinking = ref(false);
  const hasScanned = ref(false);
  const progressPercent = ref(0);
  const currentProcessingEntity = ref<string>("");
  const results = ref<EntityLinkResult[]>([]);
  const error = ref<string | null>(null);

  /**
   * Helper function to convert message HTML/Text body cleanly and strip quotes
   */
  const cleanMessageBody = (body: string): string => {
    if (!body) return "";
    let text = body;
    if (text.includes("<") && text.includes(">")) {
      const doc = new DOMParser().parseFromString(text, "text/html");
      doc.querySelectorAll("script, style").forEach((el) => el.remove());
      doc.querySelectorAll("br").forEach((el) => el.replaceWith("\n"));
      doc.querySelectorAll("p, div, tr, li").forEach((el) => {
        el.prepend(document.createTextNode("\n"));
        el.append(document.createTextNode("\n"));
      });
      text = doc.body.textContent || "";
    }

    // Normalize multi-line quote headers (e.g. "On Fri, 16 Jan 2026 at 09:40, Name <\nemail@example.com> wrote:")
    const normalizedBody = text.replace(
      /^(On\s+\w{3},\s+\d{1,2}\s+\w{3}\s+\d{4}\s+at\s+\d{1,2}:\d{2},\s+[^<]+)<\s*\n\s*([^>]+@[^>]+)>\s*wrote:/gim,
      "$1<$2> wrote:",
    );

    // Remove common email quote markers
    const lines = normalizedBody.split("\n");
    const cleanedLines: string[] = [];
    let foundQuoteStart = false;

    for (const line of lines) {
      if (
        line.match(/^On\s+.+\s+wrote:?\s*$/i) ||
        line.match(/^On\s+\w{3},?\s+\w{3}\s+\d{1,2},?\s+\d{4}/i) ||
        line.match(/^On\s+\w{3},?\s+\d{1,2}\s+\w{3}/i) ||
        line.match(/^On\s+\d{1,2}\s+\w{3}\s+\d{4}/i) ||
        line.match(
          /^On\s+\w{3},\s+\d{1,2}\s+\w{3}\s+\d{4}\s+at\s+\d{1,2}:\d{2}/i,
        ) ||
        line.match(/wrote:\s*$/) ||
        line.match(/^>/) ||
        line.match(/^-{3,}\s*Original Message\s*-{3,}$/i) ||
        line.match(/^_{3,}$/) ||
        line.match(/^From:.*Sent:.*To:/i) ||
        line.match(/^-{2,}\s*Forwarded message\s*-{2,}$/i) ||
        line.match(/<[^>]+@[^>]+>\s*wrote:?\s*$/i) ||
        line.match(/^[^>]*<\s*$/) ||
        line.match(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+>\s*wrote:?\s*$/i)
      ) {
        foundQuoteStart = true;
      }

      if (!foundQuoteStart) {
        cleanedLines.push(line);
      }
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

  /**
   * Format email address cleanly, preserving both name and email (e.g. "Ana Silva <ana@company.com>")
   */
  const formatEmailAddress = (addr: string): string => {
    if (!addr) return "";
    return addr.replace(/"/g, "").trim();
  };

  /**
   * Fetch and prepare Gmail messages for backend sync
   */
  const fetchMessagesForThreads = async (
    threadIds: string[],
  ): Promise<GmailMessageData[]> => {
    if (!threadIds || threadIds.length === 0) return [];
    if (!authStore.isGoogleAuthenticated) {
      const authed = await requestGoogleToken();
      if (!authed) return [];
    }

    const allMessages: GmailMessageData[] = [];
    const userEmail = authStore.member?.sinfoid
      ? `${authStore.member.sinfoid}@sinfo.org`
      : "";

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

      for (const msg of threadMessages) {
        const from = gmailComposable.getHeaderValue(msg, "From") || "Unknown";
        const to = gmailComposable.getHeaderValue(msg, "To") || "";
        const subject =
          gmailComposable.getHeaderValue(msg, "Subject") || "(No subject)";
        const dateStr = gmailComposable.getHeaderValue(msg, "Date") || "";

        let isoDate = "";
        if (dateStr) {
          try {
            isoDate = new Date(dateStr).toISOString();
          } catch {
            isoDate = new Date(parseInt(msg.internalDate)).toISOString();
          }
        } else {
          isoDate = new Date(parseInt(msg.internalDate)).toISOString();
        }

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
   * Automatically link Gmail threads for all entities in an event
   */
  const autoLinkEventEntities = async (
    eventId: number,
    options: { forceReScan?: boolean; onlyMyResponsibilities?: boolean } = {},
  ): Promise<EntityLinkResult[]> => {
    if (!authStore.isGoogleAuthenticated) {
      const authed = await requestGoogleToken();
      if (!authed) {
        error.value = "Google authentication is required";
        return [];
      }
    }

    isAutoLinking.value = true;
    hasScanned.value = false;
    error.value = null;
    progressPercent.value = 0;
    results.value = [];

    try {
      let companies: Company[] = [];
      let speakers: Speaker[] = [];

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

        if (existingThreads.length > 0 && !options.forceReScan) {
          try {
            const messagesToSync =
              await fetchMessagesForThreads(existingThreads);
            if (messagesToSync.length > 0) {
              await target.syncMessages(messagesToSync);
            }
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
          const threadListRes = await gmailComposable.listThreads({
            q: query,
            maxResults: 10,
          });

          if (gmailComposable.needsReauth.value) {
            await requestGoogleToken();
          }

          const matchedThreads = threadListRes?.threads || [];
          const matchedThreadIds = matchedThreads.map((t) => t.id);

          if (matchedThreadIds.length === 0) {
            results.value.push({
              entityId: target.id,
              entityName: target.name,
              entityType: target.type,
              status: "NOT_FOUND",
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

          if (newThreadIds.length > 0) {
            const messagesToSync = await fetchMessagesForThreads(newThreadIds);
            if (messagesToSync.length > 0) {
              await target.syncMessages(messagesToSync);
            }
          }

          results.value.push({
            entityId: target.id,
            entityName: target.name,
            entityType: target.type,
            status: "SUCCESS",
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
        await processEntity({
          id: company.id,
          name: company.name,
          type: "company",
          existingThreads:
            company.participations?.find((p) => p.event === eventId)
              ?.gmailThreadIds || [],
          fetchEmails: async () => {
            try {
              const repsRes = await getCompanyRepresentatives(company.id);
              const reps = repsRes.data || [];
              const emails: string[] = [];
              for (const rep of reps) {
                if (rep.contact?.mails) {
                  for (const m of rep.contact.mails) {
                    if (m.mail?.trim()) emails.push(m.mail.trim());
                  }
                }
              }
              return emails;
            } catch {
              return [];
            }
          },
          updateThreadIds: (ids) =>
            updateCompanyGmailThreadIds(company.id, ids),
          syncMessages: (msgs) => syncCompanyGmailMessages(company.id, msgs),
        });
      }

      for (const speaker of speakers) {
        await processEntity({
          id: speaker.id,
          name: speaker.name,
          type: "speaker",
          existingThreads:
            speaker.participations?.find((p) => p.event === eventId)
              ?.gmailThreadIds || [],
          fetchEmails: async () => {
            try {
              const speakerDetailRes = await getSpeakerById(speaker.id);
              const contactObj = speakerDetailRes.data?.contactObject;
              const emails: string[] = [];
              if (contactObj?.mails) {
                for (const m of contactObj.mails) {
                  if (m.mail?.trim()) emails.push(m.mail.trim());
                }
              }
              return emails;
            } catch {
              return [];
            }
          },
          updateThreadIds: (ids) =>
            updateSpeakerGmailThreadIds(speaker.id, ids),
          syncMessages: (msgs) => syncSpeakerGmailMessages(speaker.id, msgs),
        });
      }

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

  return {
    isAutoLinking,
    hasScanned,
    progressPercent,
    currentProcessingEntity,
    results,
    error,
    autoLinkEventEntities,
    fetchMessagesForThreads,
  };
};
