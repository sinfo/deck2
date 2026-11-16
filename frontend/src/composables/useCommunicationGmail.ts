import { computed, ref, watch, type ComputedRef, type Ref } from "vue";
import { useQueryCache } from "@pinia/colada";
import {
  updateCompanyGmailThreadIds,
  syncCompanyGmailMessages,
} from "@/api/companies";
import {
  updateSpeakerGmailThreadIds,
  syncSpeakerGmailMessages,
} from "@/api/speakers";
import { useAuthStore } from "@/stores/auth";
import { useGmailMessages } from "./useGmailMessages";
import { useAutoLinkGmail } from "./useAutoLinkGmail";
import { ThreadChannel, ThreadKind, type ThreadWithEntry } from "@/dto/threads";
import type { Company } from "@/dto/companies";
import type { Speaker } from "@/dto/speakers";
import {
  getThreadChannel,
  parseEmailText,
} from "@/components/communications/utils";

type EntityType = "company" | "speaker";

interface CommunicationGmailOptions {
  entity: Readonly<Ref<Company | Speaker>>;
  entityType: Readonly<Ref<EntityType>>;
  eventId: Ref<number | null>;
  linkedThreadIds: ComputedRef<string[]>;
  communications: ComputedRef<ThreadWithEntry[]>;
}

// Gmail-specific interactions belonging to the communications panel.
export const useCommunicationGmail = (options: CommunicationGmailOptions) => {
  const authStore = useAuthStore();
  const queryCache = useQueryCache();
  const { listThreads, error: listError } = useGmailMessages();
  const { fetchMessagesForThreads, error: messageError } = useAutoLinkGmail();

  const isGmailPickerOpen = ref(false);
  const gmailPickerThreadIds = ref<string[]>([]);
  const gmailPickerDefaultQuery = ref("");
  const isSyncing = ref(false);
  const gmailActionError = ref<string | null>(null);
  const availableGmailThreadsCount = ref(0);
  let availabilityRequest = 0;

  const hasManualGmailMessage = computed(() =>
    options.communications.value.some(
      (thread) =>
        getThreadChannel(thread) === ThreadChannel.Gmail &&
        !thread.gmailMessageId &&
        !thread.gmailThreadId &&
        thread.kind !== ThreadKind.ThreadKindPhoneCall &&
        thread.kind !== ThreadKind.ThreadKindMeeting &&
        !parseEmailText(thread.entry?.text).isEmail,
    ),
  );

  const isContactedWithoutThread = computed(
    () =>
      hasManualGmailMessage.value &&
      options.linkedThreadIds.value.length === 0 &&
      availableGmailThreadsCount.value > 0,
  );

  const checkAvailableGmailThreads = async (): Promise<void> => {
    const request = ++availabilityRequest;
    availableGmailThreadsCount.value = 0;
    if (
      !authStore.isGoogleAuthenticated ||
      !hasManualGmailMessage.value ||
      options.linkedThreadIds.value.length > 0
    ) {
      return;
    }

    try {
      const response = await listThreads({
        q: options.entity.value.name,
        maxResults: 5,
      });
      // Ignore results from an earlier speaker/company or edition.
      if (request !== availabilityRequest) return;
      if (!response) {
        console.error(
          "Failed to check available Gmail threads:",
          listError.value,
        );
        return;
      }

      availableGmailThreadsCount.value = response.threads.filter(
        (thread) => !options.linkedThreadIds.value.includes(thread.id),
      ).length;
    } catch (cause) {
      if (request === availabilityRequest) {
        console.error("Failed to check available Gmail threads:", cause);
      }
    }
  };

  watch(
    [
      hasManualGmailMessage,
      () => options.entity.value.id,
      options.eventId,
      options.linkedThreadIds,
      () => authStore.isGoogleAuthenticated,
    ],
    () => void checkAvailableGmailThreads(),
    { immediate: true },
  );

  const openGmailPicker = () => {
    gmailActionError.value = null;
    gmailPickerThreadIds.value = [...options.linkedThreadIds.value];
    gmailPickerDefaultQuery.value = options.entity.value.name;
    isGmailPickerOpen.value = true;
  };

  // An explicit list avoids syncing stale IDs before the query cache refreshes.
  const syncGmailMessages = async (
    threadIds: string[] = options.linkedThreadIds.value,
  ): Promise<boolean> => {
    const eventId = options.eventId.value;
    if (!eventId || threadIds.length === 0) return true;
    if (isSyncing.value) return false;

    isSyncing.value = true;
    gmailActionError.value = null;
    try {
      const messages = await fetchMessagesForThreads(threadIds);
      if (messageError.value) {
        gmailActionError.value = messageError.value;
        return false;
      }
      if (messages.length === 0) return true;

      if (options.entityType.value === "company") {
        await syncCompanyGmailMessages(
          options.entity.value.id,
          messages,
          eventId,
        );
      } else {
        await syncSpeakerGmailMessages(
          options.entity.value.id,
          messages,
          eventId,
        );
      }

      queryCache.invalidateQueries({
        key: [
          `${options.entityType.value}-communications`,
          options.entity.value.id,
        ],
      });
      return true;
    } catch (cause) {
      console.error("Failed to sync Gmail messages:", cause);
      gmailActionError.value =
        cause instanceof Error
          ? cause.message
          : "Failed to sync Gmail messages";
      return false;
    } finally {
      isSyncing.value = false;
    }
  };

  const handleGmailThreadsSave = async (threadIds: string[]) => {
    const eventId = options.eventId.value;
    if (!eventId) return;

    gmailActionError.value = null;
    try {
      if (options.entityType.value === "company") {
        await updateCompanyGmailThreadIds(
          options.entity.value.id,
          threadIds,
          eventId,
        );
      } else {
        await updateSpeakerGmailThreadIds(
          options.entity.value.id,
          threadIds,
          eventId,
        );
      }
      queryCache.invalidateQueries({
        key: [
          `${options.entityType.value}-communications`,
          options.entity.value.id,
        ],
      });
      await syncGmailMessages(threadIds);
      availableGmailThreadsCount.value = 0;
    } catch (cause) {
      console.error("Failed to update Gmail thread IDs:", cause);
      gmailActionError.value =
        cause instanceof Error ? cause.message : "Failed to link Gmail threads";
    } finally {
      gmailPickerThreadIds.value = [];
    }
  };

  return {
    isGmailPickerOpen,
    gmailPickerThreadIds,
    gmailPickerDefaultQuery,
    isSyncing,
    gmailActionError,
    isContactedWithoutThread,
    openGmailPicker,
    handleGmailThreadsSave,
    syncGmailMessages,
    checkAvailableGmailThreads,
  };
};
