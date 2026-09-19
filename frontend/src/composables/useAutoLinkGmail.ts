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
import type { Company } from "@/dto/companies";
import type { Speaker } from "@/dto/speakers";

export type EntityAutoLinkStatus =
  | "IDLE"
  | "PROCESSING"
  | "SUCCESS"
  | "ALREADY_LINKED"
  | "NOT_FOUND"
  | "ERROR"
  | "MANUALLY_LINKED";

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

export const useAutoLinkGmail = () => {
  const authStore = useAuthStore();
  const { requestGoogleToken } = useGoogleAuth();
  const gmailComposable = useGmailMessages();

  const isAutoLinking = ref(false);
  const progressPercent = ref(0);
  const currentProcessingEntity = ref<string>("");
  const results = ref<EntityLinkResult[]>([]);
  const error = ref<string | null>(null);

  /**
   * Helper function to convert message HTML/Text body cleanly
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
    return text
      .replace(/\r\n/g, "\n")
      .replace(/\n{3,}/g, "\n\n")
      .replace(/[ \t]+/g, " ")
      .replace(/^ +/gm, "")
      .replace(/ +$/gm, "")
      .trim();
  };

  /**
   * Extract clean sender name from From header
   */
  const extractEmailName = (from: string): string => {
    const match = from.match(/^"?([^"<]+)"?\s*<[^>]+>$/);
    return match ? match[1].trim() : from;
  };

  /**
   * Fetch and prepare Gmail messages for backend sync
   */
  const fetchMessagesForThreads = async (
    threadIds: string[],
  ): Promise<GmailMessageData[]> => {
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

        const isOutgoing =
          from.toLowerCase().includes("@sinfo.org") ||
          (userEmail && from.toLowerCase().includes(userEmail.toLowerCase()));

        allMessages.push({
          messageId: msg.id,
          threadId: msg.threadId,
          subject,
          from: extractEmailName(from),
          to: extractEmailName(to),
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
    options: { forceReScan?: boolean } = {},
  ): Promise<EntityLinkResult[]> => {
    if (!authStore.isGoogleAuthenticated) {
      const authed = await requestGoogleToken();
      if (!authed) {
        error.value = "Google authentication is required";
        return [];
      }
    }

    isAutoLinking.value = true;
    error.value = null;
    progressPercent.value = 0;
    results.value = [];

    try {
      // 1. Fetch companies and speakers participating in this event
      const [companiesRes, speakersRes] = await Promise.all([
        getAllCompanies({ event: eventId }),
        getAllSpeakers({ event: eventId }),
      ]);

      const companies: Company[] = companiesRes.data || [];
      const speakers: Speaker[] = speakersRes.data || [];

      const totalEntities = companies.length + speakers.length;
      if (totalEntities === 0) {
        isAutoLinking.value = false;
        return [];
      }

      let processedCount = 0;

      // 2. Process Companies
      for (const company of companies) {
        currentProcessingEntity.value = company.name;
        processedCount++;
        progressPercent.value = Math.round(
          (processedCount / totalEntities) * 100,
        );

        const participation = company.participations?.find(
          (p) => p.event === eventId,
        );
        const existingThreads = participation?.gmailThreadIds || [];

        if (existingThreads.length > 0 && !options.forceReScan) {
          results.value.push({
            entityId: company.id,
            entityName: company.name,
            entityType: "company",
            status: "ALREADY_LINKED",
            linkedThreadsCount: existingThreads.length,
            newlyLinkedCount: 0,
            threadIds: existingThreads,
            searchQueryUsed: company.name,
          });
          continue;
        }

        // Collect email addresses from company reps
        const emails: string[] = [];
        try {
          const repsRes = await getCompanyRepresentatives(company.id);
          const reps = repsRes.data || [];
          for (const rep of reps) {
            if (rep.contact?.mails) {
              for (const m of rep.contact.mails) {
                if (m.mail?.trim()) emails.push(m.mail.trim());
              }
            }
          }
        } catch {
          // Ignore error fetching reps
        }

        // Build query
        let query = "";
        if (emails.length > 0) {
          const emailQueries = emails.map((e) => `from:${e} OR to:${e}`);
          query = emailQueries.join(" OR ");
        } else {
          query = `"${company.name}"`;
        }

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
              entityId: company.id,
              entityName: company.name,
              entityType: "company",
              status: "NOT_FOUND",
              linkedThreadsCount: 0,
              newlyLinkedCount: 0,
              threadIds: [],
              searchQueryUsed: query,
            });
          } else {
            // Combine with existing
            const newThreadIds = Array.from(
              new Set([...existingThreads, ...matchedThreadIds]),
            );
            const newlyAdded = newThreadIds.filter(
              (id) => !existingThreads.includes(id),
            );

            // Update DB
            await updateCompanyGmailThreadIds(company.id, newThreadIds);

            // Sync messages
            if (newThreadIds.length > 0) {
              const messagesToSync =
                await fetchMessagesForThreads(newThreadIds);
              if (messagesToSync.length > 0) {
                await syncCompanyGmailMessages(company.id, messagesToSync);
              }
            }

            results.value.push({
              entityId: company.id,
              entityName: company.name,
              entityType: "company",
              status: "SUCCESS",
              linkedThreadsCount: newThreadIds.length,
              newlyLinkedCount: newlyAdded.length,
              threadIds: newThreadIds,
              searchQueryUsed: query,
            });
          }
        } catch (err) {
          results.value.push({
            entityId: company.id,
            entityName: company.name,
            entityType: "company",
            status: "ERROR",
            linkedThreadsCount: existingThreads.length,
            newlyLinkedCount: 0,
            threadIds: existingThreads,
            errorMessage:
              err instanceof Error ? err.message : "Failed to search Gmail",
            searchQueryUsed: query,
          });
        }
      }

      // 3. Process Speakers
      for (const speaker of speakers) {
        currentProcessingEntity.value = speaker.name;
        processedCount++;
        progressPercent.value = Math.round(
          (processedCount / totalEntities) * 100,
        );

        const participation = speaker.participations?.find(
          (p) => p.event === eventId,
        );
        const existingThreads = participation?.gmailThreadIds || [];

        if (existingThreads.length > 0 && !options.forceReScan) {
          results.value.push({
            entityId: speaker.id,
            entityName: speaker.name,
            entityType: "speaker",
            status: "ALREADY_LINKED",
            linkedThreadsCount: existingThreads.length,
            newlyLinkedCount: 0,
            threadIds: existingThreads,
            searchQueryUsed: speaker.name,
          });
          continue;
        }

        // Fetch detailed contact info for speaker
        const emails: string[] = [];
        try {
          const speakerDetailRes = await getSpeakerById(speaker.id);
          const contactObj = speakerDetailRes.data?.contactObject;
          if (contactObj?.mails) {
            for (const m of contactObj.mails) {
              if (m.mail?.trim()) emails.push(m.mail.trim());
            }
          }
        } catch {
          // Ignore error
        }

        let query = "";
        if (emails.length > 0) {
          const emailQueries = emails.map((e) => `from:${e} OR to:${e}`);
          query = emailQueries.join(" OR ");
        } else {
          query = `"${speaker.name}"`;
        }

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
              entityId: speaker.id,
              entityName: speaker.name,
              entityType: "speaker",
              status: "NOT_FOUND",
              linkedThreadsCount: 0,
              newlyLinkedCount: 0,
              threadIds: [],
              searchQueryUsed: query,
            });
          } else {
            const newThreadIds = Array.from(
              new Set([...existingThreads, ...matchedThreadIds]),
            );
            const newlyAdded = newThreadIds.filter(
              (id) => !existingThreads.includes(id),
            );

            await updateSpeakerGmailThreadIds(speaker.id, newThreadIds);

            if (newThreadIds.length > 0) {
              const messagesToSync =
                await fetchMessagesForThreads(newThreadIds);
              if (messagesToSync.length > 0) {
                await syncSpeakerGmailMessages(speaker.id, messagesToSync);
              }
            }

            results.value.push({
              entityId: speaker.id,
              entityName: speaker.name,
              entityType: "speaker",
              status: "SUCCESS",
              linkedThreadsCount: newThreadIds.length,
              newlyLinkedCount: newlyAdded.length,
              threadIds: newThreadIds,
              searchQueryUsed: query,
            });
          }
        } catch (err) {
          results.value.push({
            entityId: speaker.id,
            entityName: speaker.name,
            entityType: "speaker",
            status: "ERROR",
            linkedThreadsCount: existingThreads.length,
            newlyLinkedCount: 0,
            threadIds: existingThreads,
            errorMessage:
              err instanceof Error ? err.message : "Failed to search Gmail",
            searchQueryUsed: query,
          });
        }
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
    }
  };

  /**
   * Mark an entity as manually linked after user manually links it in GmailThreadPicker
   */
  const markAsManuallyLinked = (entityId: string, threadIds: string[]) => {
    const resultItem = results.value.find((r) => r.entityId === entityId);
    if (resultItem) {
      resultItem.status = "MANUALLY_LINKED";
      resultItem.linkedThreadsCount = threadIds.length;
      resultItem.threadIds = threadIds;
    }
  };

  return {
    isAutoLinking,
    progressPercent,
    currentProcessingEntity,
    results,
    error,
    autoLinkEventEntities,
    markAsManuallyLinked,
  };
};
