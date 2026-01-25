<template>
  <Card class="w-full h-auto lg:h-[650px] 2xl:h-[800px] flex flex-col">
    <CardHeader class="flex-shrink-0">
      <div
        class="flex flex-col sm:flex-row sm:items-center justify-between gap-2"
      >
        <div class="flex-1">
          <CardTitle class="text-base sm:text-lg"> Communications</CardTitle>
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
        <div class="flex-shrink-0 flex gap-1">
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
                  <Mail :size="16" :stroke-width="2" class="mr-1" />
                  <span v-if="currentParticipationGmailThreadIds.length > 0">
                    {{ currentParticipationGmailThreadIds.length }} Gmail
                  </span>
                  <span v-else>Link Gmail</span>
                </Button>
              </TooltipTrigger>
              <TooltipContent>
                <p>
                  {{
                    currentParticipationGmailThreadIds.length > 0
                      ? `${currentParticipationGmailThreadIds.length} Gmail thread(s) linked`
                      : "Link Gmail threads to this participation"
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
                  @click="syncGmailMessages"
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
        class="flex-1 flex items-center justify-center"
      >
        <div class="text-center text-muted-foreground">
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

      <div
        v-else
        ref="messagesContainer"
        class="flex-1 overflow-y-auto p-2 sm:p-4 space-y-3 sm:space-y-4 scroll-smooth"
      >
        <div
          v-for="thread in sortedCommunications"
          :key="thread.id"
          :class="[
            'flex gap-2',
            thread.kind === ThreadKind.ThreadKindPhoneCall
              ? 'justify-center'
              : getMessageDirection(thread.kind) === 'outgoing'
                ? 'justify-end'
                : 'justify-start',
          ]"
        >
          <!-- Author avatar for messages (on the left side) -->
          <div
            v-if="thread.kind !== ThreadKind.ThreadKindPhoneCall"
            class="flex flex-col items-center gap-1"
          >
            <Image
              v-if="getAuthorAvatar(getMessageAuthor(thread))"
              :src="getAuthorAvatar(getMessageAuthor(thread))"
              :alt="getMessageAuthor(thread)?.name || 'Member'"
              :class="avatarClasses(thread)"
            />
            <div
              v-else
              class="w-8 h-8 rounded-full bg-gray-300 flex items-center justify-center"
            >
              <span class="text-sm font-medium">{{
                getMessageAuthor(thread)?.name?.charAt(0) || "?"
              }}</span>
            </div>
            <div class="text-xs text-center max-w-20 leading-tight">
              <div>
                {{ getFirstName(getMessageAuthor(thread)?.name) }}
              </div>
              <div>
                {{ getLastName(getMessageAuthor(thread)?.name) }}
              </div>
            </div>
          </div>

          <div
            :class="[
              'max-w-[85%] sm:max-w-[80%] flex flex-col group/message',
              getMessageDirection(thread.kind) === 'outgoing'
                ? 'items-end'
                : 'items-start',
            ]"
          >
            <!-- Bubble skin -->
            <div
              :class="[
                'w-full rounded-lg p-2 sm:p-3 space-y-2',
                thread.kind === ThreadKind.ThreadKindPhoneCall
                  ? 'bg-purple-100 text-purple-800 border border-purple-200'
                  : getMessageDirection(thread.kind) === 'outgoing'
                    ? 'bg-primary text-primary-foreground'
                    : 'bg-muted',
              ]"
            >
              <!-- Message header -->
              <div class="flex items-center gap-2 text-xs opacity-75">
                <div class="flex items-center gap-1">
                  <div
                    :class="['w-2 h-2 rounded-full', getKindColor(thread.kind)]"
                  ></div>
                  <span>{{ getKindLabel(thread.kind) }}</span>
                </div>

                <div class="flex items-center gap-1">
                  <div
                    :class="[
                      'w-2 h-2 rounded-full',
                      getStatusColor(thread.status),
                    ]"
                  ></div>
                </div>

                <span>{{ formatDate(thread.posted) }}</span>
              </div>

              <!-- Edit mode -->
              <div
                v-if="editingThreadId === thread.id"
                class="text-sm space-y-2"
              >
                <Textarea
                  v-model="editText"
                  class="w-full resize-none min-h-[60px] max-h-[160px]"
                  :disabled="updatePostMutation?.isLoading?.value"
                />
                <div class="flex justify-end gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    class="text-primary"
                    :disabled="updatePostMutation?.isLoading?.value"
                    @click="cancelEdit"
                  >
                    Cancel
                  </Button>
                  <Button
                    size="sm"
                    class="border border-white"
                    :disabled="
                      !editText.trim() || updatePostMutation?.isLoading?.value
                    "
                    @click="saveEdit"
                  >
                    {{
                      updatePostMutation?.isLoading?.value
                        ? "Saving..."
                        : "Save"
                    }}
                  </Button>
                </div>
              </div>

              <!-- VIEW MODE -->
              <div v-else>
                <!-- Message content -->
                <div v-if="thread.entry" class="text-sm">
                  <div class="whitespace-pre-wrap">{{ thread.entry.text }}</div>
                  <div
                    v-if="
                      thread.entry.updated &&
                      thread.entry.updated !== thread.entry.posted
                    "
                    class="text-xs opacity-60 mt-1"
                  >
                    Edited {{ formatDate(thread.entry.updated) }}
                  </div>
                </div>

                <!-- Phone call indicator -->
                <div
                  v-else-if="thread.kind === ThreadKind.ThreadKindPhoneCall"
                  class="text-sm italic flex items-center justify-center gap-2"
                >
                  <span class="text-lg">📞</span>
                  <span>Phone call</span>
                </div>

                <!-- Meeting indicator -->
                <div v-else-if="thread.meeting" class="text-sm italic">
                  📅 Meeting scheduled
                </div>

                <!-- No content fallback -->
                <div v-else class="text-sm italic opacity-60">
                  No message content
                </div>
              </div>

              <!-- Comments indicator -->
              <div
                v-if="thread.comments.length > 0"
                class="text-xs opacity-75 border-t pt-2"
              >
                💬 {{ thread.comments.length }} comment{{
                  thread.comments.length === 1 ? "" : "s"
                }}
              </div>
            </div>

            <!-- Actions -->
            <div :class="['mt-1 transition-opacity opacity-100']">
              <button
                class="p-1 rounded focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black/10 text-muted-foreground hover:opacity-80"
                title="Edit"
                aria-label="Edit message"
                :disabled="deleteThreadMutation?.isLoading?.value"
                @click="startEdit(thread)"
              >
                <Pencil :size="16" :stroke-width="2" class="align-middle" />
              </button>
              <button
                class="p-1 rounded focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-destructive/30 text-destructive hover:opacity-90 disabled:opacity-50"
                title="Delete"
                aria-label="Delete message"
                :disabled="
                  deleteThreadMutation?.isLoading?.value ||
                  updatePostMutation?.isLoading?.value
                "
                @click="requestDelete(thread)"
              >
                <Trash2 :size="16" :stroke-width="2" class="align-middle" />
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Message input area -->
      <div v-if="canSendMessages" class="flex-shrink-0 border-t p-3 sm:p-4">
        <!-- Error message -->
        <div
          v-if="postThreadMutation?.error.value"
          class="mb-3 p-2 bg-red-50 border border-red-200 rounded-md text-red-700 text-sm"
        >
          <div class="font-medium">Failed to send message</div>
          <div class="text-xs mt-1">
            {{ postThreadMutation.error.value.message || "Please try again" }}
          </div>
        </div>

        <div class="flex flex-col sm:flex-row gap-2">
          <div class="flex-1">
            <Textarea
              v-model="newMessage"
              :disabled="selectedEventId !== latestEvent?.id"
              placeholder="Type your message..."
              class="w-full resize-none border rounded-md p-2 text-sm min-h-[50px] sm:min-h-[60px] max-h-[100px] sm:max-h-[120px]"
              @keydown.enter.ctrl="sendMessage"
              @keydown.enter.meta="sendMessage"
              @input="onMessageInput"
            />
          </div>
          <div class="flex sm:flex-col gap-2">
            <Button
              :disabled="
                selectedEventId !== latestEvent?.id ||
                !newMessage.trim() ||
                postThreadMutation?.isLoading.value
              "
              size="sm"
              class="px-3 flex-1 sm:flex-none"
              @click="sendMessage"
            >
              {{ postThreadMutation?.isLoading.value ? "Sending..." : "Send" }}
            </Button>
            <select
              v-model="messageKind"
              :disabled="selectedEventId !== latestEvent?.id"
              class="text-xs border rounded px-2 py-1 flex-1 sm:flex-none"
            >
              <option :value="ThreadKind.ThreadKindTo">Outgoing</option>
              <option :value="ThreadKind.ThreadKindFrom">Incoming</option>
              <option :value="ThreadKind.ThreadKindPhoneCall">
                Phone Call
              </option>
              <!-- Broken for now <option :value="ThreadKind.ThreadKindMeeting">Meeting</option> -->
              <option :value="ThreadKind.ThreadKindTemplate">Template</option>
            </select>
          </div>
        </div>
        <div class="text-xs text-muted-foreground mt-2">
          Press Ctrl+Enter to send
        </div>
      </div>
      <div v-else class="flex-shrink-0 border-t p-3 sm:p-4">
        <div class="text-center text-muted-foreground text-sm">
          Communications feature coming soon for {{ entityType }}s
        </div>
      </div>
    </CardContent>
  </Card>

  <!-- Gmail Thread Picker Modal -->
  <GmailThreadPicker
    v-model:open="isGmailPickerOpen"
    :initial-thread-ids="gmailPickerThreadIds"
    :default-search-query="gmailPickerDefaultQuery"
    @save="handleGmailThreadsSave"
  />
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick } from "vue";
import { useQuery, useQueryCache } from "@pinia/colada";
import { getAllEvents } from "@/api/events";
import { getAllMembers } from "@/api/members";
import {
  updateCompanyGmailThreadIds,
  syncCompanyGmailMessages,
  type GmailMessageData,
} from "@/api/companies";
import {
  updateSpeakerGmailThreadIds,
  syncSpeakerGmailMessages,
} from "@/api/speakers";
import { ThreadKind, ThreadStatus } from "@/dto/threads";
import type {
  ParticipationCommunications,
  ThreadWithEntry,
} from "@/dto/threads";
import type { Speaker } from "@/dto/speakers";
import type { Company } from "@/dto/companies";
import type { Member } from "@/dto/members";
import { useEventStore } from "@/stores/event";
import { useAuthStore } from "@/stores/auth";
import { useGmailMessages } from "@/composables/useGmailMessages";
import { useGoogleAuth } from "@/composables/useGoogleAuth";
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
import Image from "./Image.vue";
import {
  EmailTemplate,
  openTemplateInNewTab,
  templateHumanReadableNames,
  type AnyEmailVariableInput,
} from "@/lib/templates";
import type { Event } from "@/dto/events";
import Textarea from "./ui/textarea/Textarea.vue";
import { useUpdatePostMutation } from "@/mutations/posts.ts";
import { Pencil, Trash2, Mail, RefreshCw } from "lucide-vue-next";
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
  participations?: Array<{ event: number }>;
  canSendMessages?: boolean;
  templates?: TemplateWithVariables[];
  fetchCommunications: (
    id: string,
  ) => Promise<{ data: ParticipationCommunications[] }>;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  postThreadMutation?: any;
}

type Author = Member | Speaker | Company;

const props = withDefaults(defineProps<CommunicationsProps>(), {
  canSendMessages: false,
  templates: () => [],
  participations: () => [],
  postThreadMutation: undefined,
});

const newMessage = ref("");
const messageKind = ref<ThreadKind>(ThreadKind.ThreadKindTo);
const messagesContainer = ref<HTMLElement>();
const eventStore = useEventStore();
const selectedEventId = ref<number | null>(
  eventStore.selectedEvent?.id ?? null,
);
const selectedTemplate = ref<TemplateWithVariables>();

const editingThreadId = ref<string | null>(null);
const editingPostId = ref<string | null>(null);
const editText = ref("");

// Gmail thread picker state
const isGmailPickerOpen = ref(false);
const gmailPickerThreadIds = ref<string[]>([]);
const gmailPickerDefaultQuery = ref("");
const queryCache = useQueryCache();

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

const membersById = computed(() => {
  if (!membersData.value?.data) return new Map();

  const map = new Map();
  membersData.value.data.forEach((member) => {
    map.set(member.id, member);
  });
  return map;
});

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

// Gmail picker functions
const currentParticipationGmailThreadIds = computed(() => {
  if (!communicationsData.value || !selectedEventId.value) return [];
  const participation = communicationsData.value.find(
    (p) => p.event === selectedEventId.value,
  );
  return participation?.gmailThreadIds || [];
});

const openGmailPicker = () => {
  gmailPickerThreadIds.value = [...currentParticipationGmailThreadIds.value];
  // Default search query is the company/speaker name
  gmailPickerDefaultQuery.value = props.entity.name;
  isGmailPickerOpen.value = true;
};

const handleGmailThreadsSave = async (threadIds: string[]) => {
  try {
    if (props.entityType === "company") {
      await updateCompanyGmailThreadIds(props.entity.id, threadIds);
    } else {
      await updateSpeakerGmailThreadIds(props.entity.id, threadIds);
    }
    // Invalidate the communications query to refresh data
    queryCache.invalidateQueries({
      key: [`${props.entityType}-communications`, props.entity.id],
    });
    // Auto-sync after linking
    await syncGmailMessages();
  } catch (err) {
    console.error("Failed to update Gmail thread IDs:", err);
  } finally {
    gmailPickerThreadIds.value = [];
  }
};

// Gmail sync functionality
const authStore = useAuthStore();
const gmailComposable = useGmailMessages();
const { requestGoogleToken } = useGoogleAuth();
const isSyncing = ref(false);

/**
 * Strips HTML tags and converts to clean plain text
 */
const stripHtmlToText = (html: string): string => {
  // Create a temporary element to parse HTML
  const doc = new DOMParser().parseFromString(html, "text/html");

  // Remove script and style elements
  doc.querySelectorAll("script, style").forEach((el) => el.remove());

  // Replace common block elements with newlines
  doc.querySelectorAll("br").forEach((el) => el.replaceWith("\n"));
  doc.querySelectorAll("p, div, tr, li").forEach((el) => {
    el.prepend(document.createTextNode("\n"));
    el.append(document.createTextNode("\n"));
  });

  // Get text content
  let text = doc.body.textContent || "";

  // Clean up whitespace
  text = text
    .replace(/\r\n/g, "\n") // Normalize line endings
    .replace(/\n{3,}/g, "\n\n") // Max 2 consecutive newlines
    .replace(/[ \t]+/g, " ") // Collapse multiple spaces/tabs
    .replace(/^ +/gm, "") // Remove leading spaces on each line
    .replace(/ +$/gm, "") // Remove trailing spaces on each line
    .trim();

  return text;
};

/**
 * Extracts a clean display name from an email address
 * "John Doe <john@example.com>" -> "John Doe"
 * "john@example.com" -> "john@example.com"
 */
const extractEmailName = (email: string): string => {
  const match = email.match(/^"?([^"<]+)"?\s*<[^>]+>$/);
  return match ? match[1].trim() : email;
};

const syncGmailMessages = async () => {
  if (!currentParticipationGmailThreadIds.value.length) {
    return;
  }

  // Check if Google authentication is needed
  if (!authStore.isGoogleAuthenticated) {
    const success = await requestGoogleToken();
    if (!success) {
      console.error("Failed to authenticate with Google");
      return;
    }
  }

  isSyncing.value = true;

  try {
    // Fetch all messages from linked Gmail threads
    const allMessages: GmailMessageData[] = [];

    for (const gmailThreadId of currentParticipationGmailThreadIds.value) {
      // Get all messages in this thread using the threads API
      const threadMessages = await gmailComposable.getMessagesByThreadId(
        gmailThreadId,
        { format: "full" },
      );

      // Check if re-authentication is needed (token expired during request)
      if (gmailComposable.needsReauth.value) {
        const success = await requestGoogleToken();
        if (!success) {
          console.error("Failed to re-authenticate with Google");
          return;
        }
        // Retry the current thread after re-authentication
        const retryMessages = await gmailComposable.getMessagesByThreadId(
          gmailThreadId,
          { format: "full" },
        );
        if (gmailComposable.needsReauth.value) {
          console.error("Still unable to authenticate after retry");
          return;
        }
        threadMessages.push(...retryMessages);
      }

      for (const msg of threadMessages) {
        const from = gmailComposable.getHeaderValue(msg, "From") || "Unknown";
        const to = gmailComposable.getHeaderValue(msg, "To") || "";
        const subject =
          gmailComposable.getHeaderValue(msg, "Subject") || "(No subject)";
        const dateStr = gmailComposable.getHeaderValue(msg, "Date") || "";

        // Parse date to ISO format
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

        // Get message body - prefer plain text, fallback to HTML
        let body =
          gmailComposable.getMessageBody(msg, false) || msg.snippet || "";

        // If the body looks like HTML, convert it to plain text
        if (body.includes("<") && body.includes(">")) {
          body = stripHtmlToText(body);
        }

        // Clean up the body further - remove excessive quoted content
        // Remove common email quote markers
        const lines = body.split("\n");
        const cleanedLines: string[] = [];
        let foundQuoteStart = false;

        for (const line of lines) {
          // Detect start of quoted content
          if (
            line.match(/^On\s+.+\s+wrote:?\s*$/i) || // "On Wed, 17 Dec 2025 at 07:05, Name wrote:"
            line.match(/^On\s+\w{3},?\s+\w{3}\s+\d{1,2},?\s+\d{4}/i) || // "On Wed, Nov 26, 2025" or "On Wed Nov 26 2025"
            line.match(/^On\s+\w{3},?\s+\d{1,2}\s+\w{3}/i) || // "On Wed, 17 Dec" (start of quote attribution)
            line.match(/^On\s+\d{1,2}\s+\w{3}\s+\d{4}/i) || // "On 17 Dec 2025"
            line.match(/wrote:\s*$/) || // Any line ending with "wrote:"
            line.match(/^>/) || // Quoted line starting with >
            line.match(/^-{3,}\s*Original Message\s*-{3,}$/i) ||
            line.match(/^_{3,}$/) ||
            line.match(/^From:.*Sent:.*To:/i) ||
            line.match(/^-{2,}\s*Forwarded message\s*-{2,}$/i) ||
            line.match(/<[^>]+@[^>]+>\s*wrote:?\s*$/i) // "<email@example.com> wrote:"
          ) {
            foundQuoteStart = true;
          }

          if (!foundQuoteStart) {
            cleanedLines.push(line);
          }
        }

        // Use cleaned content if we removed quotes, otherwise use original
        const cleanBody =
          cleanedLines.length > 0 ? cleanedLines.join("\n").trim() : body;

        // Determine if outgoing (sent by us)
        const userEmail = authStore.member?.sinfoid
          ? `${authStore.member.sinfoid}@sinfo.org`
          : "";
        const isOutgoing =
          from.toLowerCase().includes("@sinfo.org") ||
          from.toLowerCase().includes(userEmail.toLowerCase());

        allMessages.push({
          messageId: msg.id,
          threadId: msg.threadId,
          subject,
          from: extractEmailName(from),
          to: extractEmailName(to),
          date: isoDate,
          body: cleanBody,
          isOutgoing,
        });
      }
    }

    if (allMessages.length === 0) {
      return;
    }

    // Send to backend for sync
    if (props.entityType === "company") {
      await syncCompanyGmailMessages(props.entity.id, allMessages);
    } else {
      await syncSpeakerGmailMessages(props.entity.id, allMessages);
    }

    // Refresh communications
    queryCache.invalidateQueries({
      key: [`${props.entityType}-communications`, props.entity.id],
    });
  } catch (err) {
    console.error("Failed to sync Gmail messages:", err);
  } finally {
    isSyncing.value = false;
  }
};

const saveEdit = async () => {
  const id = editingPostId.value;
  const text = editText.value.trim();
  if (!id || !text) return;

  updatePostMutation.postId.value = id;
  updatePostMutation.text.value = text;

  try {
    updatePostMutation.mutate();
  } catch (e) {
    console.error("Edit failed:", e);
    return;
  } finally {
    editingThreadId.value = null;
    editingPostId.value = null;
    editText.value = "";
    scrollToBottom();
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
    deleteThreadMutation.mutate();
  } catch (e) {
    console.error("Delete failed:", e);
  }
};

// Watch for changes in communications and scroll to bottom
watch(
  () => sortedCommunications.value,
  () => {
    scrollToBottom();
  },
  { flush: "post" },
);

// Watch for when data is first loaded and scroll to bottom
watch(
  () => communicationsData.value,
  (newData) => {
    if (newData) {
      scrollToBottom();
    }
  },
  { immediate: true },
);

// Watch for loading state changes to ensure scroll happens after data loads
watch(
  () => isLoading.value,
  (loading, wasLoading) => {
    // When loading finishes, and we have data, scroll to bottom
    if (wasLoading && !loading && sortedCommunications.value.length > 0) {
      // Add a small delay to ensure DOM has updated
      setTimeout(() => {
        scrollToBottom();
      }, 100);
    }
  },
);

// Watch for selected event changes and scroll to bottom
watch(
  () => selectedEventId.value,
  () => {
    // Small delay to let the filtered communications update
    setTimeout(() => {
      if (sortedCommunications.value.length > 0) {
        scrollToBottom();
      }
    }, 50);
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

const getMessageDirection = (kind: ThreadKind): "incoming" | "outgoing" => {
  return kind === ThreadKind.ThreadKindTo ||
    kind === ThreadKind.ThreadKindTemplate
    ? "outgoing"
    : "incoming";
};

const getMessageAuthor = (thread: ThreadWithEntry): Author | null => {
  const direction = getMessageDirection(thread.kind);

  if (direction === "outgoing" && thread.entry?.member) {
    return getMemberById(thread.entry?.member);
  } else if (direction === "incoming") {
    return props.entity;
  }
  return null;
};

const getAuthorAvatar = (entity: Author | null): string | undefined => {
  if (!entity) return undefined;

  if ("imgs" in entity) {
    return entity.imgs?.internal;
  } else if ("img" in entity) {
    return entity.img;
  }

  return undefined;
};

const avatarClasses = (thread: ThreadWithEntry) => {
  const direction = getMessageDirection(thread.kind);

  // People related avatars: always circular
  if (direction === "outgoing" || props.entityType === "speaker") {
    return ["w-8 h-8 object-cover", "rounded-full"];
  }

  return [
    "w-8 h-8 bg-white p-1",
    "object-contain",
    "rounded-sm",
    "border border-gray-100",
    "shadow-sm",
    "sm:rounded-none",
    "sm:w-9",
    "sm:h-9",
    "md:w-12",
    "md:h-10",
    "md:rounded-md",
  ];
};

const getKindLabel = (kind: ThreadKind): string => {
  switch (kind) {
    case ThreadKind.ThreadKindTo:
      return "Sent";
    case ThreadKind.ThreadKindFrom:
      return "Received";
    case ThreadKind.ThreadKindPhoneCall:
      return "Phone Call";
    case ThreadKind.ThreadKindMeeting:
      return "Meeting";
    case ThreadKind.ThreadKindTemplate:
      return "Template";
    default:
      return "Unknown";
  }
};

const getKindColor = (kind: ThreadKind): string => {
  switch (kind) {
    case ThreadKind.ThreadKindTo:
      return "bg-blue-500";
    case ThreadKind.ThreadKindFrom:
      return "bg-green-500";
    case ThreadKind.ThreadKindPhoneCall:
      return "bg-purple-500";
    case ThreadKind.ThreadKindMeeting:
      return "bg-orange-500";
    case ThreadKind.ThreadKindTemplate:
      return "bg-gray-500";
    default:
      return "bg-gray-400";
  }
};

const getStatusColor = (status: ThreadStatus): string => {
  switch (status) {
    case ThreadStatus.ThreadStatusApproved:
      return "bg-green-500";
    case ThreadStatus.ThreadStatusReviewed:
      return "bg-yellow-500";
    case ThreadStatus.ThreadStatusPending:
      return "bg-red-500";
    default:
      return "bg-gray-400";
  }
};

const formatDate = (dateString: string): string => {
  const date = new Date(dateString);
  const now = new Date();
  const diffInDays = Math.floor(
    (now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24),
  );

  if (diffInDays === 0) {
    return date.toLocaleTimeString("en-US", {
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    });
  } else if (diffInDays === 1) {
    return "Yesterday";
  } else if (diffInDays < 7) {
    return date.toLocaleDateString("en-US", { weekday: "short" });
  } else {
    return date.toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
  }
};

const sendMessage = async () => {
  if (!newMessage.value.trim() || !props.postThreadMutation) return;

  try {
    // Set the thread data for the mutation
    // eslint-disable-next-line vue/no-mutating-props
    props.postThreadMutation.threadData.value = {
      text: newMessage.value,
      kind: messageKind.value,
    };

    await props.postThreadMutation.mutate();

    newMessage.value = "";
    selectedTemplate.value = undefined;

    scrollToBottom();
  } catch (error) {
    console.error("Failed to send message:", error);
  }
};

const getMemberById = (memberId: string) => {
  return membersById.value.get(memberId);
};

const getFirstName = (fullName: string | undefined): string => {
  if (!fullName) return "Unknown";
  const parts = fullName.trim().split(/\s+/);
  return parts[0] || "Unknown";
};

const getLastName = (fullName: string | undefined): string => {
  if (!fullName) return "";
  const parts = fullName.trim().split(/\s+/);
  return parts[1] || "";
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
    openTemplateInNewTab(template, variables);

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
