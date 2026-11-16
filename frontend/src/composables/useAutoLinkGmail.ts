import { ref } from "vue";
import { useQueryCache } from "@pinia/colada";
import { useAuthStore } from "@/stores/auth";
import { useToast } from "@/lib/toast";
import { useGoogleAuth } from "./useGoogleAuth";
import { useGmailMessages } from "./useGmailMessages";
import { createGmailSyncClient } from "./gmailSync/client";
import {
  errorMessage,
  type EntityLinkResult,
  type SyncResult,
} from "./gmailSync/common";
import { runFullGmailSync, type FullSyncOptions } from "./gmailSync/fullSync";
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

  const timestampKey = (eventId: number): string =>
    `gmail_last_sync_timestamp_${scopeKey(eventId)}`;

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
    work: () => Promise<SyncResult<EntityLinkResult[]>>,
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
      // Record when the scan starts, so messages arriving mid-scan aren't skipped.
      const startedAt = Date.now();

      try {
        const token = await gmail.ensureToken();
        if (!token.ok) {
          error.value = token.error;
          return [];
        }

        const scan = await work();
        if (!scan.ok) {
          error.value = scan.error;
          return [];
        }

        results.value = scan.value;
        // An empty initial scan must remain eligible for a full retry.
        const previousSync = Number(
          localStorage.getItem(timestampKey(eventId)),
        );
        const hadPreviousSync =
          Number.isFinite(previousSync) && previousSync > 0;
        if (
          !scan.value.some((item) => item.status === "ERROR") &&
          (scan.value.length > 0 || (kind === "recent" && hadPreviousSync))
        ) {
          localStorage.setItem(timestampKey(eventId), String(startedAt));
        }

        queryCache.invalidateQueries({ key: ["company-communications"] });
        queryCache.invalidateQueries({ key: ["speaker-communications"] });
        queryCache.invalidateQueries({ key: ["my-responsibilities"] });
        return scan.value;
      } catch (cause) {
        error.value = errorMessage(cause);
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

  const autoLinkEventEntities = (
    eventId: number,
    options: FullSyncOptions = {},
  ): Promise<EntityLinkResult[]> =>
    runSync(eventId, "full", () =>
      runFullGmailSync(eventId, options, gmail, (name, completed, total) => {
        currentProcessingEntity.value = name;
        progressPercent.value = Math.round((completed / total) * 100);
      }),
    );

  const syncRecentGmailUpdates = (
    eventId: number,
  ): Promise<EntityLinkResult[]> =>
    runSync(eventId, "recent", async () => {
      const stored = localStorage.getItem(timestampKey(eventId));
      const lastSync = stored ? Number(stored) : NaN;
      if (!Number.isFinite(lastSync) || lastSync <= 0) {
        return runFullGmailSync(
          eventId,
          { onlyMyResponsibilities: true },
          gmail,
          (name, completed, total) => {
            currentProcessingEntity.value = name;
            progressPercent.value = Math.round((completed / total) * 100);
          },
        );
      }
      return runRecentGmailSync(eventId, lastSync, gmail);
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
