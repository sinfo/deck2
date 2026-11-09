<template>
  <Card
    class="w-full h-auto lg:h-[650px] 2xl:h-[800px] flex flex-col gap-0 py-0"
  >
    <CardHeader class="flex-shrink-0 px-4 pt-3 pb-1 sm:px-6 sm:pt-4 sm:pb-1.5">
      <div
        class="flex flex-col sm:flex-row sm:items-center justify-between gap-2"
      >
        <div class="flex-1">
          <CardTitle class="text-base sm:text-lg">Communications</CardTitle>
          <CardDescription class="text-sm">
            {{ description }}
          </CardDescription>
        </div>
        <div v-if="templates?.length" class="flex-shrink-0">
          <Select
            v-model="selectedTemplate"
            :disabled="selectedEventId !== latestEvent?.id"
          >
            <SelectTrigger>
              <SelectValue placeholder="Templates" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem
                v-for="template in templates"
                :key="template.template"
                :value="template"
              >
                {{ templateHumanReadableNames[template.template] }}
              </SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div
          v-if="authStore.isGoogleAuthenticated"
          class="flex-shrink-0 flex gap-1"
        >
          <TooltipProvider>
            <Tooltip>
              <TooltipTrigger as-child>
                <Button
                  variant="outline"
                  size="sm"
                  :class="[
                    currentParticipationGmailThreadIds.length > 0
                      ? 'text-blue-500 border-blue-500'
                      : '',
                  ]"
                  :disabled="!selectedEventId"
                  @click="openGmailPicker"
                >
                  <GmailIcon class="w-4 h-4 mr-1.5" />
                  <span>View Threads</span>
                </Button>
              </TooltipTrigger>
              <TooltipContent>
                <p>
                  {{
                    currentParticipationGmailThreadIds.length > 0
                      ? `${currentParticipationGmailThreadIds.length} Gmail thread(s) linked`
                      : "View and link Gmail threads"
                  }}
                </p>
              </TooltipContent>
            </Tooltip>
          </TooltipProvider>
          <TooltipProvider>
            <Tooltip>
              <TooltipTrigger as-child>
                <Button
                  variant="outline"
                  size="sm"
                  :disabled="
                    !selectedEventId ||
                    currentParticipationGmailThreadIds.length === 0 ||
                    isSyncing
                  "
                  @click="syncGmailMessages()"
                >
                  <RefreshCw
                    :size="16"
                    :stroke-width="2"
                    :class="[isSyncing ? 'animate-spin' : '']"
                  />
                </Button>
              </TooltipTrigger>
              <TooltipContent>
                <p>Sync Gmail messages to communications</p>
              </TooltipContent>
            </Tooltip>
          </TooltipProvider>
        </div>
        <div class="flex-shrink-0">
          <Select v-model="selectedEventId">
            <SelectTrigger>
              <SelectValue placeholder="Edition" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem
                v-for="event in availableEvents"
                :key="event.id"
                :value="event.id"
              >
                {{ event.name }}
              </SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>
    </CardHeader>

    <CardContent class="flex-1 flex flex-col overflow-hidden p-0">
      <p
        v-if="gmailActionError"
        role="alert"
        class="px-3 py-2 text-xs text-destructive break-words"
      >
        {{ gmailActionError }}
      </p>
      <div v-if="isLoading" class="flex-1 flex items-center justify-center">
        <div class="text-muted-foreground">Loading communications...</div>
      </div>

      <div v-else-if="error" class="flex-1 flex items-center justify-center">
        <div class="text-center text-red-500">
          <div class="text-lg mb-2">⚠️</div>
          <div>Failed to load communications</div>
          <div class="text-xs">{{ error?.message }}</div>
        </div>
      </div>

      <div
        v-else-if="!sortedCommunications?.length"
        class="flex-1 flex items-center justify-center p-6"
      >
        <!-- Notice when entity is contacted but no Gmail thread could be linked -->
        <div
          v-if="isContactedWithoutThread"
          class="text-center max-w-sm mx-auto space-y-3"
        >
          <div
            class="w-12 h-12 rounded-full bg-amber-500/10 text-amber-600 dark:text-amber-400 flex items-center justify-center mx-auto"
          >
            <MailWarning class="w-6 h-6" />
          </div>
          <div class="space-y-1">
            <h3 class="font-semibold text-sm">No Gmail thread found</h3>
            <p class="text-xs text-muted-foreground leading-relaxed">
              This {{ entityType }} is marked as
              <strong class="text-foreground font-semibold">{{
                currentStatusLabel
              }}</strong
              >, but no matching email thread was found automatically in Gmail.
            </p>
          </div>
          <div class="pt-1">
            <Button
              variant="outline"
              size="sm"
              class="gap-1.5 text-xs"
              @click="openGmailPicker"
            >
              <Link2 class="w-3.5 h-3.5" />
              Link Gmail thread manually
            </Button>
          </div>
          <div v-if="selectedEventId" class="text-[11px] opacity-60">
            For event: {{ getEventName(selectedEventId) }}
          </div>
        </div>

        <div v-else class="text-center text-muted-foreground">
          <div class="text-lg mb-2">💬</div>
          <div>No communications yet</div>
          <div class="text-xs">
            Start a conversation with this {{ entityType }}
          </div>
          <div v-if="selectedEventId" class="text-xs mt-2 opacity-60">
            For event: {{ getEventName(selectedEventId) }}
          </div>
          <div v-else class="text-xs mt-2 opacity-60 text-red-500">
            No event selected
          </div>
        </div>
      </div>

      <div v-else class="flex-1 flex flex-col overflow-hidden">
        <!-- Warning banner when communications exist but Gmail thread is not linked -->
        <div
          v-if="
            isContactedWithoutThread &&
            selectedChannelTab !== 'linkedin' &&
            selectedChannelTab !== 'calls' &&
            selectedChannelTab !== 'other'
          "
          class="mx-3 mt-2 mb-1 p-2.5 rounded-md border border-amber-500/30 bg-amber-500/10 text-amber-800 dark:text-amber-300 text-xs flex items-center justify-between gap-2 flex-shrink-0"
        >
          <div class="flex items-center gap-2 min-w-0">
            <AlertTriangle
              class="w-4 h-4 text-amber-600 dark:text-amber-400 flex-shrink-0"
            />
            <span class="truncate">
              Marked as <strong>{{ currentStatusLabel }}</strong
              >, but no Gmail thread is linked.
            </span>
          </div>
          <Button
            variant="outline"
            size="sm"
            class="h-7 text-xs px-2.5 border-amber-500/30 hover:bg-amber-500/20 flex-shrink-0 gap-1"
            @click="openGmailPicker"
          >
            <Link2 class="w-3 h-3" />
            Link thread
          </Button>
        </div>

        <CommunicationChannelTabs
          v-model:channel="selectedChannelTab"
          v-model:gmail-thread="selectedGmailThreadTab"
          :total-count="sortedCommunications.length"
          :gmail-count="gmailCommunicationsCount"
          :linked-in-count="linkedInCommunicationsCount"
          :calls-count="callsCount"
          :other-count="otherCommunicationsCount"
          :gmail-thread-tabs="availableGmailThreadTabs"
        />

        <div
          ref="messagesContainer"
          class="flex-1 min-w-0 overflow-y-auto p-2 sm:p-4 space-y-3 sm:space-y-4 scroll-smooth"
        >
          <!-- Filtered empty state -->
          <div
            v-if="filteredCommunications.length === 0"
            class="h-full flex items-center justify-center p-8 text-center text-muted-foreground"
          >
            <div class="flex flex-col items-center">
              <div class="mb-3 flex justify-center">
                <LinkedInIcon
                  v-if="selectedChannelTab === 'linkedin'"
                  class="w-10 h-10 rounded-sm"
                />
                <GmailIcon
                  v-else-if="selectedChannelTab === 'gmail'"
                  class="w-10 h-10"
                />
                <Phone
                  v-else-if="selectedChannelTab === 'calls'"
                  class="w-10 h-10 text-muted-foreground/60"
                />
                <MessageSquare
                  v-else
                  class="w-10 h-10 text-muted-foreground/60"
                />
              </div>
              <div class="text-sm font-medium">
                {{
                  selectedChannelTab === "linkedin"
                    ? "Sem comunicações do LinkedIn"
                    : selectedChannelTab === "gmail"
                      ? "Sem comunicações do Gmail"
                      : selectedChannelTab === "calls"
                        ? "Sem registos de chamadas"
                        : "Sem comunicações de Outro"
                }}
              </div>
              <div class="text-xs opacity-70 mt-1">
                {{
                  selectedChannelTab === "calls"
                    ? 'Alterne para a aba "All" ou registe uma chamada abaixo.'
                    : 'Alterne para a aba "All" ou envie uma mensagem neste canal.'
                }}
              </div>
            </div>
          </div>

          <template
            v-for="(thread, index) in filteredCommunications"
            :key="thread.id"
          >
            <!-- Thread visual divider when viewing all and thread changes -->
            <div
              v-if="showThreadDivider(index)"
              class="flex items-center gap-2 my-3 text-xs text-muted-foreground"
            >
              <div class="h-px bg-border flex-1"></div>
              <Badge
                variant="outline"
                class="font-normal text-[11px] gap-1 py-0.5"
              >
                <LinkedInIcon
                  v-if="getThreadChannel(thread) === ThreadChannel.LinkedIn"
                  class="w-3 h-3 rounded-[2px]"
                />
                <MessageSquare
                  v-else-if="getThreadChannel(thread) === ThreadChannel.Other"
                  class="w-3 h-3 text-zinc-500"
                />
                <GmailIcon v-else class="w-3 h-3" />
                <span class="max-w-[220px] sm:max-w-[320px] truncate">
                  {{ getDividerLabel(thread) }}
                </span>
              </Badge>
              <div class="h-px bg-border flex-1"></div>
            </div>

            <CommunicationMessage
              v-model:edit-text="editText"
              :thread="thread"
              :entity="entity"
              :entity-type="entityType"
              :members-by-id="membersById"
              :is-editing="editingThreadId === thread.id"
              :is-saving="updatePostMutation.isLoading.value"
              :is-deleting="deleteThreadMutation.isLoading.value"
              @start-edit="startEdit"
              @cancel-edit="cancelEdit"
              @save-edit="saveEdit"
              @request-delete="requestDelete"
            />
          </template>
        </div>
      </div>

      <CommunicationComposer
        v-model:message="newMessage"
        v-model:channel="messageChannel"
        v-model:kind="messageKind"
        :can-send-messages="canSendMessages"
        :entity-type="entityType"
        :disabled="selectedEventId !== latestEvent?.id"
        :is-sending="postThreadMutation?.isLoading.value ?? false"
        :error-message="postThreadMutation?.error.value?.message"
        @send="sendMessage"
        @message-input="onMessageInput"
      />
    </CardContent>
  </Card>

  <!-- Gmail Thread Picker Modal -->
  <GmailThreadPicker
    v-model:open="isGmailPickerOpen"
    :initial-thread-ids="gmailPickerThreadIds"
    :default-search-query="gmailPickerDefaultQuery"
    @save="handleGmailThreadsSave"
  />

  <MissingGenderDialog v-model:open="isMissingGenderDialogOpen" />
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick, toRef } from "vue";
import { useQuery } from "@pinia/colada";
import { getAllEvents } from "@/api/events";
import { getAllMembers } from "@/api/members";
import { ThreadChannel, ThreadKind } from "@/dto/threads";
import type {
  ParticipationCommunications,
  ThreadWithEntry,
} from "@/dto/threads";
import type { Speaker } from "@/dto/speakers";
import type { Company } from "@/dto/companies";
import type { Member } from "@/dto/members";
import { useEventStore } from "@/stores/event";
import { useAuthStore } from "@/stores/auth";
import { useCommunicationGmail } from "@/composables/useCommunicationGmail";
import { useCommunicationThreads } from "@/composables/useCommunicationThreads";
import CommunicationChannelTabs from "./communications/CommunicationChannelTabs.vue";
import CommunicationComposer from "./communications/CommunicationComposer.vue";
import CommunicationMessage from "./communications/CommunicationMessage.vue";
import { getDividerLabel, getThreadChannel } from "./communications/utils";
import { usePostCompanyThreadMutation } from "@/mutations/companies";
import { usePostSpeakerThreadMutation } from "@/mutations/speakers";
import Card from "./ui/card/Card.vue";
import CardContent from "./ui/card/CardContent.vue";
import CardDescription from "./ui/card/CardDescription.vue";
import CardHeader from "./ui/card/CardHeader.vue";
import CardTitle from "./ui/card/CardTitle.vue";
import Button from "./ui/button/Button.vue";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "./ui/select";
import {
  EmailTemplate,
  openTemplateInNewTab,
  templateHumanReadableNames,
  type AnyEmailVariableInput,
} from "@/lib/templates";
import MissingGenderDialog from "./MissingGenderDialog.vue";
import type { Event } from "@/dto/events";
import type { ParticipationStatus } from "@/dto";
import { humanReadableParticipationStatus } from "@/dto";
import { useUpdatePostMutation } from "@/mutations/posts.ts";
import { GmailIcon, LinkedInIcon } from "@/components/icons";
import {
  RefreshCw,
  AlertTriangle,
  MailWarning,
  Link2,
  Phone,
  MessageSquare,
} from "lucide-vue-next";
import { Badge } from "@/components/ui/badge";
import { useDeleteThreadMutation } from "@/mutations/threads.ts";
import GmailThreadPicker from "./GmailThreadPicker.vue";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "./ui/tooltip";

interface TemplateWithVariables {
  template: EmailTemplate;
  variables: AnyEmailVariableInput[];
}

interface CommunicationsProps {
  entity: Company | Speaker;
  entityType: "company" | "speaker";
  description: string;
  participations?: Array<{
    event: number;
    status?: ParticipationStatus;
    gmailThreadIds?: string[];
  }>;
  canSendMessages?: boolean;
  templates?: TemplateWithVariables[];
  fetchCommunications: (
    id: string,
  ) => Promise<{ data: ParticipationCommunications[] }>;
  postThreadMutation?:
    | ReturnType<typeof usePostCompanyThreadMutation>
    | ReturnType<typeof usePostSpeakerThreadMutation>;
}

const props = withDefaults(defineProps<CommunicationsProps>(), {
  canSendMessages: false,
  templates: () => [],
  participations: () => [],
  postThreadMutation: undefined,
});

const newMessage = ref("");
const messageKind = ref<ThreadKind>(ThreadKind.ThreadKindTo);
const messageChannel = ref<ThreadChannel>(ThreadChannel.Gmail);
const messagesContainer = ref<HTMLElement>();
const eventStore = useEventStore();
const authStore = useAuthStore();
const selectedEventId = ref<number | null>(
  eventStore.selectedEvent?.id ?? null,
);
const selectedTemplate = ref<TemplateWithVariables>();
const isMissingGenderDialogOpen = ref(false);

const editingThreadId = ref<string | null>(null);
const editingPostId = ref<string | null>(null);
const editText = ref("");

const updatePostMutation = useUpdatePostMutation();
const deleteThreadMutation = useDeleteThreadMutation();

updatePostMutation.entityType.value = props.entityType;
updatePostMutation.entityId.value = props.entity.id;
deleteThreadMutation.entityType.value = props.entityType;
deleteThreadMutation.entityId.value = props.entity.id;

const scrollToBottom = () => {
  nextTick(() => {
    if (messagesContainer.value) {
      messagesContainer.value.scrollTo({
        top: messagesContainer.value.scrollHeight,
        behavior: "smooth",
      });
    }
  });
};

// Fetch all events to get proper names
const { data: eventsData } = useQuery({
  key: () => ["events"],
  query: () => getAllEvents(),
});

// Fetch all members to get names and avatars
const { data: membersData } = useQuery({
  key: () => ["members"],
  query: () => getAllMembers(),
});

// Computed property to get events with participations
const availableEvents = computed(() => {
  if (!props.participations || !eventsData.value?.data) return [];

  const events = eventsData.value.data;
  const participationEventIds = new Set(
    props.participations.map((p) => p.event),
  );

  return events
    .filter((event) => participationEventIds.has(event.id))
    .map((event) => ({
      id: event.id,
      name: event.name,
    }));
});

const membersById = computed<Map<string, Member>>(
  () =>
    new Map(
      (membersData.value?.data ?? []).map((member) => [member.id, member]),
    ),
);

const {
  data: communicationsData,
  isLoading,
  error,
} = useQuery({
  key: () => [`${props.entityType}-communications`, props.entity.id],
  query: () => props.fetchCommunications(props.entity.id).then((it) => it.data),
});

const sortedCommunications = computed<ThreadWithEntry[]>(() => {
  if (!communicationsData.value) return [];
  return [...communicationsData.value]
    .filter((it) => it.event === selectedEventId.value)
    .flatMap((it) => it.communications)
    .sort(
      (a, b) => new Date(a.posted).getTime() - new Date(b.posted).getTime(),
    ) as ThreadWithEntry[];
});

const {
  selectedChannelTab,
  selectedGmailThreadTab,
  callsCount,
  gmailCommunicationsCount,
  linkedInCommunicationsCount,
  otherCommunicationsCount,
  availableGmailThreadTabs,
  filteredCommunications,
  showThreadDivider,
} = useCommunicationThreads(sortedCommunications);

const onMessageInput = () => {
  props.postThreadMutation?.reset?.();
};

const startEdit = (thread: ThreadWithEntry) => {
  if (!thread.entry) return;

  editingThreadId.value = thread.id;
  editingPostId.value = thread.entry.id;

  editText.value = thread.entry.text ?? "";
};

const cancelEdit = () => {
  editingThreadId.value = null;
  editingPostId.value = null;
  editText.value = "";
};

const currentParticipationGmailThreadIds = computed(() => {
  if (!communicationsData.value || !selectedEventId.value) return [];
  const participation = communicationsData.value.find(
    (p) => p.event === selectedEventId.value,
  );
  return participation?.gmailThreadIds || [];
});

const currentParticipation = computed(() => {
  if (!props.participations || !selectedEventId.value) return null;
  return (
    props.participations.find((p) => p.event === selectedEventId.value) || null
  );
});

const currentParticipationStatus = computed<ParticipationStatus | undefined>(
  () => currentParticipation.value?.status,
);

const currentStatusLabel = computed(() => {
  const status = currentParticipationStatus.value;
  return status ? humanReadableParticipationStatus[status] || status : "";
});

const {
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
} = useCommunicationGmail({
  entity: toRef(props, "entity"),
  entityType: toRef(props, "entityType"),
  eventId: selectedEventId,
  linkedThreadIds: currentParticipationGmailThreadIds,
  communications: sortedCommunications,
});

const saveEdit = async () => {
  const id = editingPostId.value;
  const text = editText.value.trim();
  if (!id || !text) return;

  updatePostMutation.postId.value = id;
  updatePostMutation.text.value = text;

  try {
    await updatePostMutation.mutateAsync();
    cancelEdit();
    scrollToBottom();
  } catch (e) {
    console.error("Edit failed:", e);
  }
};

const requestDelete = async (thread: ThreadWithEntry) => {
  if (!thread.entry) return;
  const ok = window.confirm(
    "Delete this message? This action cannot be undone.",
  );
  if (!ok) return;

  deleteThreadMutation.threadId.value = thread.id;

  try {
    await deleteThreadMutation.mutateAsync();
  } catch (e) {
    console.error("Delete failed:", e);
  }
};

watch(
  [filteredCommunications, selectedEventId, isLoading],
  () => scrollToBottom(),
  { flush: "post", immediate: true },
);

// Watch for changes in the selected channel or sub-thread tab and scroll to bottom
watch(
  () => selectedChannelTab.value,
  (newTab) => {
    if (newTab === "linkedin") {
      messageChannel.value = ThreadChannel.LinkedIn;
      if (messageKind.value === ThreadKind.ThreadKindPhoneCall) {
        messageKind.value = ThreadKind.ThreadKindTo;
      }
    } else if (newTab === "gmail") {
      messageChannel.value = ThreadChannel.Gmail;
      if (messageKind.value === ThreadKind.ThreadKindPhoneCall) {
        messageKind.value = ThreadKind.ThreadKindTo;
      }
    } else if (newTab === "calls") {
      messageChannel.value = ThreadChannel.Other;
      messageKind.value = ThreadKind.ThreadKindPhoneCall;
    } else if (newTab === "other") {
      messageChannel.value = ThreadChannel.Other;
      if (messageKind.value === ThreadKind.ThreadKindPhoneCall) {
        messageKind.value = ThreadKind.ThreadKindTo;
      }
    }
    selectedGmailThreadTab.value = "all";
  },
);

// Watch for changes in the event store
watch(
  () => eventStore.selectedEvent,
  (newEvent) => {
    if (newEvent && selectedEventId.value !== newEvent.id) {
      selectedEventId.value = newEvent.id;
    }
  },
  { immediate: true },
);

const sendMessage = async () => {
  if (!newMessage.value.trim() || !props.postThreadMutation) return;

  try {
    // Set the thread data for the mutation
    // eslint-disable-next-line vue/no-mutating-props
    props.postThreadMutation.threadData.value = {
      text: newMessage.value,
      kind: messageKind.value,
      channel: messageChannel.value,
    };

    await props.postThreadMutation.mutateAsync();

    newMessage.value = "";
    selectedTemplate.value = undefined;

    scrollToBottom();

    if (messageChannel.value === ThreadChannel.Gmail) {
      checkAvailableGmailThreads();
    }
  } catch (error) {
    console.error("Failed to send message:", error);
  }
};

const getEventName = (eventId: number): string => {
  const event = eventsData.value?.data.find((e) => e.id === eventId);
  return event?.name || `Event ${eventId}`;
};

watch(
  () => selectedTemplate.value,
  (newTemplate) => {
    if (!newTemplate) return;

    const { template, variables } = newTemplate;

    if (template.endsWith("_PT") && !authStore.member?.contactObject?.gender) {
      selectedTemplate.value = undefined;
      isMissingGenderDialogOpen.value = true;
      return;
    }

    openTemplateInNewTab(template, variables);

    messageChannel.value = ThreadChannel.Gmail;
    messageKind.value = ThreadKind.ThreadKindTemplate;
    newMessage.value = `Send "${templateHumanReadableNames[template]}" template`;
  },
);

const latestEvent = computed(() => {
  // Get latest event
  return eventsData.value?.data?.reduce(
    (latest, event) => {
      if (!latest || new Date(event.end || 0) > new Date(latest?.end || 0)) {
        return event;
      }
      return latest;
    },
    null as Event | null,
  );
});
</script>
