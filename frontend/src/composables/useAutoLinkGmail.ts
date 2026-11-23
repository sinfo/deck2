import { ref } from "vue";
import { useQueryCache } from "@pinia/colada";
import { useAuthStore } from "@/stores/auth";
import { useToast } from "@/lib/toast";
import { useGoogleAuth } from "./useGoogleAuth";
import { useGmailMessages } from "./useGmailMessages";
import { createGmailSyncClient } from "./gmailSync/client";
import {
  errorMessage,
  failure,
  success,
  type EntityLinkResult,
  type SyncResult,
} from "./gmailSync/common";
import { runFullGmailSync } from "./gmailSync/fullSync";
import { runRecentGmailSync } from "./gmailSync/recentSync";

export type {
  EntityAutoLinkStatus,
  EntityLinkResult,
} from "./gmailSync/common";

const CONTACTED_PARTICIPATION_STATUSES = [
  "CONTACTED",
  "IN_CONVERSATIONS",
  "ACCEPTED",
  "REJECTED",
  "GIVEN_UP",
  "ANNOUNCED",
] as const;

export { CONTACTED_PARTICIPATION_STATUSES };
export const isContactedParticipationStatus = (
  status?: EntityLinkResult["participationStatus"],
): boolean =>
  status !== undefined &&
  CONTACTED_PARTICIPATION_STATUSES.some((item) => item === status);

// Keep state and concurrent requests shared between components using this composable.
const isAutoLinking = ref(false);
const hasScanned = ref(false);
const progressPercent = ref(0);
const currentProcessingEntity = ref("");
const results = ref<EntityLinkResult[]>([]);
const error = ref<string | null>(null);
const activeSyncPromises = new Map<string, Promise<EntityLinkResult[]>>();

interface SyncReport {
  entities: EntityLinkResult[];
  historyId?: string;
}
let lastWarnTimestamp = 0;

export const useAutoLinkGmail = () => {
  const auth = useAuthStore();
  const { requestGoogleToken } = useGoogleAuth();
  const { toast } = useToast();
  const queryCache = useQueryCache();
  const gmail = createGmailSyncClient(
    auth,
    useGmailMessages(),
    requestGoogleToken,
  );

  const scopeKey = (eventId: number): string =>
    `${auth.memberSinfoid || auth.decoded?.sinfoid?.toLowerCase().trim() || "unknown"}:${eventId}`;

  const historyKey = (eventId: number): string =>
    `gmail_history_id_${scopeKey(eventId)}:${(auth.connectedGoogleEmail ?? auth.sinfoEmail ?? "").toLowerCase()}`;

  const withHistory = (
    scan: SyncResult<EntityLinkResult[]>,
    historyId?: string,
  ): SyncResult<SyncReport> =>
    scan.ok
      ? success({ entities: scan.value, historyId })
      : failure(scan.error);

  const syncFull = async (eventId: number): Promise<SyncResult<SyncReport>> => {
    // Capture the position before scanning to avoid missing incoming replies.
    const checkpoint = await gmail.getHistoryId();
    return withHistory(
      await runFullGmailSync(eventId, gmail, (name, completed, total) => {
        currentProcessingEntity.value = name;
        progressPercent.value = Math.round((completed / total) * 100);
      }),
      checkpoint.ok ? checkpoint.value : undefined,
    );
  };

  const getUnlinkedContacted = (
    list: EntityLinkResult[] = results.value,
  ): EntityLinkResult[] =>
    list.filter(
      (item) =>
        item.status === "NOT_FOUND" &&
        isContactedParticipationStatus(item.participationStatus),
    );

  const warnUnlinkedContacted = (list: EntityLinkResult[] = results.value) => {
    const unlinked = getUnlinkedContacted(list);
    if (unlinked.length === 0 || Date.now() - lastWarnTimestamp < 5000) return;
    lastWarnTimestamp = Date.now();

    const names = unlinked
      .slice(0, 3)
      .map((item) => item.entityName)
      .join(", ");
    const extra = unlinked.length > 3 ? ` and ${unlinked.length - 3} more` : "";
    toast.warning({
      title: "Gmail Threads Not Found",
      description: `Could not find Gmail threads for ${unlinked.length} contacted entity/entities: ${names}${extra}.`,
    });
  };

  // The same member/edition may only run one sync at a time.
  const runSync = (
    eventId: number,
    kind: "full" | "recent",
    work: () => Promise<SyncResult<SyncReport>>,
  ): Promise<EntityLinkResult[]> => {
    const key = scopeKey(eventId);
    const running = activeSyncPromises.get(key);
    if (running) return running;

    const promise = (async (): Promise<EntityLinkResult[]> => {
      isAutoLinking.value = true;
      error.value = null;
      results.value = [];
      hasScanned.value = false;
      progressPercent.value = 0;
      currentProcessingEntity.value = "";
      try {
        const token = await gmail.ensureToken();
        if (!token.ok) {
          error.value = token.error;
          console.error(
            `[Gmail sync] Could not authorize SINFO ${eventId}: ${token.error}`,
          );
          return [];
        }

        const scan = await work();
        if (!scan.ok) {
          error.value = scan.error;
          console.error(
            `[Gmail sync] Could not start ${kind} sync for SINFO ${eventId}: ${scan.error}`,
          );
          return [];
        }

        results.value = scan.value.entities;
        const failed = results.value.filter((item) => item.status === "ERROR");
        if (failed.length > 0) {
          console.warn(
            `[Gmail sync] SINFO ${eventId}: ${failed.length} of ${results.value.length} entities failed (${kind} sync). View details in Settings.`,
          );
        }
        // Advance the mailbox checkpoint only after successful processing.
        if (
          scan.value.historyId &&
          failed.length === 0 &&
          (results.value.length > 0 || kind === "recent")
        ) {
          localStorage.setItem(historyKey(eventId), scan.value.historyId);
        }

        queryCache.invalidateQueries({ key: ["company-communications"] });
        queryCache.invalidateQueries({ key: ["speaker-communications"] });
        queryCache.invalidateQueries({ key: ["my-responsibilities"] });
        return results.value;
      } catch (cause) {
        error.value = errorMessage(cause);
        console.error(
          `[Gmail sync] Unexpected error during SINFO ${eventId} ${kind} sync: ${error.value}`,
        );
        return results.value;
      } finally {
        isAutoLinking.value = false;
        hasScanned.value = true;
        activeSyncPromises.delete(key);
      }
    })();

    activeSyncPromises.set(key, promise);
    return promise;
  };

  const autoLinkEventEntities = (eventId: number) =>
    runSync(eventId, "full", () => syncFull(eventId));

  const syncRecentGmailUpdates = (
    eventId: number,
  ): Promise<EntityLinkResult[]> =>
    runSync(eventId, "recent", async () => {
      const historyId = localStorage.getItem(historyKey(eventId));
      if (!historyId) return syncFull(eventId);

      const changes = await gmail.getChangedThreadIds(historyId);
      if (!changes.ok) return failure(changes.error);
      // An expired history ID requires a new baseline.
      if (!changes.value) return syncFull(eventId);

      return withHistory(
        await runRecentGmailSync(eventId, changes.value.threadIds, gmail),
        changes.value.historyId,
      );
    });

  // Public helper for the Gmail Threads view: no locally thrown exceptions.
  const fetchMessagesForThreads = async (threadIds: string[]) => {
    error.value = null;
    const response = await gmail.fetchMessages(threadIds);
    if (!response.ok) {
      error.value = response.error;
      return [];
    }
    return response.value;
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
