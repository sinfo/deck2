<template>
  <Card class="w-full h-auto lg:h-[650px] 2xl:h-[800px] flex flex-col">
    <CardHeader class="flex-shrink-0">
      <div
        class="flex flex-col sm:flex-row sm:items-center justify-between gap-2"
      >
        <div class="flex-1">
          <CardTitle class="text-base sm:text-lg"> Communications </CardTitle>
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
              'max-w-[85%] sm:max-w-[80%] rounded-lg p-2 sm:p-3 space-y-2',
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
                <span>{{ getStatusLabel(thread.status) }}</span>
              </div>

              <span>{{ formatDate(thread.posted) }}</span>
            </div>

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
              :disabled="selectedEventId !== latestEvent?.id"
              v-model="newMessage"
              placeholder="Type your message..."
              class="w-full resize-none border rounded-md p-2 text-sm min-h-[50px] sm:min-h-[60px] max-h-[100px] sm:max-h-[120px]"
              @keydown.enter.ctrl="sendMessage"
              @keydown.enter.meta="sendMessage"
              @input="
                postThreadMutation && (postThreadMutation.error.value = null)
              "
            />
          </div>
          <div class="flex sm:flex-col gap-2">
            <Button
              @click="sendMessage"
              :disabled="
                selectedEventId !== latestEvent?.id ||
                !newMessage.trim() ||
                postThreadMutation?.isLoading.value
              "
              size="sm"
              class="px-3 flex-1 sm:flex-none"
            >
              {{ postThreadMutation?.isLoading.value ? "Sending..." : "Send" }}
            </Button>
            <select
              :disabled="selectedEventId !== latestEvent?.id"
              v-model="messageKind"
              class="text-xs border rounded px-2 py-1 flex-1 sm:flex-none"
            >
              <option :value="ThreadKind.ThreadKindTo">Outgoing</option>
              <option :value="ThreadKind.ThreadKindFrom">Incoming</option>
              <option :value="ThreadKind.ThreadKindPhoneCall">
                Phone Call
              </option>
              <option :value="ThreadKind.ThreadKindMeeting">Meeting</option>
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
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick } from "vue";
import { useQuery } from "@pinia/colada";
import { getAllEvents } from "@/api/events";
import { getAllMembers } from "@/api/members";
import { getSpeakerById } from "@/api/speakers";
import { getCompanyById } from "@/api/companies";
import { ThreadKind, ThreadStatus } from "@/dto/threads";
import type { ParticipationCommunications, ThreadWithEntry } from "@/dto/threads";
import type { Speaker } from "@/dto/speakers";
import type { Company } from "@/dto/companies";
import type { Member } from "@/dto/members";
import { useEventStore } from "@/stores/event";
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
  postThreadMutation?: any;
}

type Author = Member | Speaker | Company;

const props = withDefaults(defineProps<CommunicationsProps>(), {
  canSendMessages: false,
  templates: () => [],
});

const newMessage = ref("");
const messageKind = ref<ThreadKind>(ThreadKind.ThreadKindTo);
const messagesContainer = ref<HTMLElement>();
const eventStore = useEventStore();
const selectedEventId = ref<number | null>(
  eventStore.selectedEvent?.id ?? null,
);
const selectedTemplate = ref<TemplateWithVariables>();

// Function to scroll to bottom of messages with smooth animation
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

// Computed property to get members by ID
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

const sortedCommunications = computed(() => {
  if (!communicationsData.value) return [];
  return [...communicationsData.value]
    .filter((it) => it.event === selectedEventId.value)
    .flatMap((it) => it.communications)
    .sort(
      (a, b) => new Date(a.posted).getTime() - new Date(b.posted).getTime(),
    );
});

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
    // When loading finishes and we have data, scroll to bottom
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

const getStatusLabel = (status: ThreadStatus): string => {
  switch (status) {
    case ThreadStatus.ThreadStatusApproved:
      return "Approved";
    case ThreadStatus.ThreadStatusReviewed:
      return "Reviewed";
    case ThreadStatus.ThreadStatusPending:
      return "Pending";
    default:
      return "Unknown";
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
    });
  } else if (diffInDays === 1) {
    return "Yesterday";
  } else if (diffInDays < 7) {
    return date.toLocaleDateString("en-US", { weekday: "short" });
  } else {
    return date.toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
    });
  }
};

const sendMessage = async () => {
  if (!newMessage.value.trim() || !props.postThreadMutation) return;

  try {
    // Set the thread data for the mutation
    props.postThreadMutation.threadData.value = {
      text: newMessage.value,
      kind: messageKind.value,
    };

    // Execute the mutation
    await props.postThreadMutation.mutate();

    // Clear the message input on success
    newMessage.value = "";
    selectedTemplate.value = undefined;

    // Scroll to bottom after sending message
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
