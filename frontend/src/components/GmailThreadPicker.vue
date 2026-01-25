<template>
  <AlertDialog v-model:open="isOpen">
    <AlertDialogContent class="max-w-3xl max-h-[80vh] flex flex-col">
      <AlertDialogHeader class="flex-shrink-0">
        <AlertDialogTitle>Link Gmail Threads</AlertDialogTitle>
        <AlertDialogDescription>
          Search and select Gmail threads to link to this communication.
        </AlertDialogDescription>
      </AlertDialogHeader>

      <div class="flex-1 overflow-hidden flex flex-col gap-4 py-4">
        <!-- Search input -->
        <div class="flex gap-2">
          <Input
            v-model="searchQuery"
            placeholder="Search Gmail messages..."
            class="flex-1"
            @keydown.enter="searchMessages"
          />
          <Button :disabled="isSearching" @click="searchMessages">
            {{ isSearching ? "Searching..." : "Search" }}
          </Button>
        </div>

        <!-- Currently linked threads -->
        <div v-if="selectedThreadIds.length > 0" class="space-y-2">
          <div class="text-sm font-medium">
            Linked Threads ({{ selectedThreadIds.length }})
          </div>
          <div class="flex flex-wrap gap-2">
            <Badge
              v-for="threadId in selectedThreadIds"
              :key="threadId"
              variant="secondary"
              class="flex items-center gap-1"
            >
              <span class="truncate max-w-[200px]">{{ threadId }}</span>
              <button
                class="ml-1 hover:text-destructive"
                @click="removeThreadId(threadId)"
              >
                <X :size="14" />
              </button>
            </Badge>
          </div>
        </div>

        <!-- Error message -->
        <div
          v-if="errorMessage"
          class="p-3 bg-red-50 border border-red-200 rounded-md text-red-700 text-sm"
        >
          {{ errorMessage }}
        </div>

        <!-- Google auth required -->
        <div
          v-if="!isGoogleConnected"
          class="flex-1 flex flex-col items-center justify-center gap-4 py-8"
        >
          <div class="text-muted-foreground text-center">
            <div class="mb-2">Connect to Google to search Gmail messages</div>
          </div>
          <Button :disabled="isSigningIn" @click="handleGoogleSignIn">
            {{ isSigningIn ? "Connecting..." : "Connect to Google" }}
          </Button>
        </div>

        <!-- Search results -->
        <div
          v-else-if="!hasSearched"
          class="flex-1 flex items-center justify-center text-muted-foreground"
        >
          Enter a search query and click Search to find Gmail threads
        </div>

        <div
          v-else-if="isSearching"
          class="flex-1 flex items-center justify-center"
        >
          <div class="text-muted-foreground">Loading messages...</div>
        </div>

        <div
          v-else-if="groupedMessages.length === 0"
          class="flex-1 flex items-center justify-center text-muted-foreground"
        >
          No messages found for "{{ lastSearchQuery }}"
        </div>

        <div v-else class="flex-1 overflow-y-auto space-y-2">
          <div class="text-sm text-muted-foreground mb-2">
            Found {{ groupedMessages.length }} thread(s)
          </div>
          <div
            v-for="thread in groupedMessages"
            :key="thread.threadId"
            :class="[
              'p-3 border rounded-lg cursor-pointer transition-colors',
              selectedThreadIds.includes(thread.threadId)
                ? 'bg-primary/10 border-primary'
                : 'hover:bg-muted',
            ]"
            @click="toggleThreadSelection(thread.threadId)"
          >
            <div class="flex items-start gap-3">
              <Checkbox
                :checked="selectedThreadIds.includes(thread.threadId)"
                @update:checked="toggleThreadSelection(thread.threadId)"
              />
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2 mb-1">
                  <span class="font-medium truncate">{{
                    thread.from || "Unknown Sender"
                  }}</span>
                  <span class="text-xs text-muted-foreground flex-shrink-0">
                    {{ formatDate(thread.date) }}
                  </span>
                </div>
                <div class="text-sm font-medium truncate">
                  {{ thread.subject || "(No Subject)" }}
                </div>
                <div class="text-sm text-muted-foreground truncate mt-1">
                  {{ thread.snippet }}
                </div>
                <div
                  v-if="thread.messageCount > 1"
                  class="text-xs text-muted-foreground mt-1"
                >
                  {{ thread.messageCount }} messages in thread
                </div>
              </div>
            </div>
          </div>

          <!-- Load more button -->
          <div v-if="nextPageToken" class="pt-2">
            <Button
              variant="outline"
              class="w-full"
              :disabled="isLoadingMore"
              @click="loadMoreMessages"
            >
              {{ isLoadingMore ? "Loading..." : "Load More" }}
            </Button>
          </div>
        </div>
      </div>

      <AlertDialogFooter class="flex-shrink-0">
        <AlertDialogCancel @click="handleCancel">Cancel</AlertDialogCancel>
        <Button :disabled="isSaving" @click="handleSave">
          {{ isSaving ? "Saving..." : "Save" }}
        </Button>
      </AlertDialogFooter>
    </AlertDialogContent>
  </AlertDialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from "vue";
import {
  AlertDialog,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogCancel,
} from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Checkbox } from "@/components/ui/checkbox";
import { X } from "lucide-vue-next";
import {
  useGmailMessages,
  type GmailMessage,
} from "@/composables/useGmailMessages";
import { useGoogleAuth } from "@/composables/useGoogleAuth";
import { useAuthStore } from "@/stores/auth";

interface GroupedThread {
  threadId: string;
  subject: string;
  from: string;
  date: string;
  snippet: string;
  messageCount: number;
}

const props = defineProps<{
  open: boolean;
  initialThreadIds?: string[];
  defaultSearchQuery?: string;
}>();

const emit = defineEmits<{
  (e: "update:open", value: boolean): void;
  (e: "save", threadIds: string[]): void;
}>();

const { listMessages, getMessage, getHeaderValue, needsReauth } =
  useGmailMessages();
const { signInWithGoogle, requestGoogleToken, isSigningIn } = useGoogleAuth();
const authStore = useAuthStore();

const isOpen = computed({
  get: () => props.open,
  set: (value) => emit("update:open", value),
});

const searchQuery = ref(props.defaultSearchQuery || "");
const lastSearchQuery = ref("");
const hasSearched = ref(false);
const isSearching = ref(false);
const isLoadingMore = ref(false);
const isSaving = ref(false);
const errorMessage = ref<string | null>(null);
const messages = ref<GmailMessage[]>([]);
const nextPageToken = ref<string | undefined>(undefined);
const selectedThreadIds = ref<string[]>([...(props.initialThreadIds || [])]);

const isGoogleConnected = computed(() => authStore.isGoogleAuthenticated);

// Group messages by thread ID
const groupedMessages = computed<GroupedThread[]>(() => {
  const threadMap = new Map<string, GroupedThread>();

  for (const msg of messages.value) {
    const existing = threadMap.get(msg.threadId);
    const msgDate = new Date(parseInt(msg.internalDate));
    const subject = getHeaderValue(msg, "Subject") || "";
    const from = getHeaderValue(msg, "From") || "";

    if (!existing || new Date(existing.date) < msgDate) {
      threadMap.set(msg.threadId, {
        threadId: msg.threadId,
        subject,
        from: extractEmailName(from),
        date: msgDate.toISOString(),
        snippet: msg.snippet,
        messageCount: existing ? existing.messageCount + 1 : 1,
      });
    } else {
      existing.messageCount++;
    }
  }

  return Array.from(threadMap.values()).sort(
    (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime(),
  );
});

const extractEmailName = (from: string): string => {
  // Extract name from "Name <email@example.com>" format
  const match = from.match(/^([^<]+)</);
  if (match) {
    return match[1].trim().replace(/"/g, "");
  }
  return from;
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
  } else if (diffInDays < 7) {
    return date.toLocaleDateString("en-US", {
      weekday: "short",
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    });
  } else {
    return date.toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      year: date.getFullYear() !== now.getFullYear() ? "numeric" : undefined,
    });
  }
};

const searchMessages = async () => {
  if (!searchQuery.value.trim()) return;

  isSearching.value = true;
  errorMessage.value = null;
  hasSearched.value = true;
  lastSearchQuery.value = searchQuery.value;
  messages.value = [];
  nextPageToken.value = undefined;

  try {
    let result = await listMessages({
      q: searchQuery.value,
      maxResults: 20,
    });

    // Handle re-authentication if needed
    if (needsReauth.value) {
      const success = await requestGoogleToken();
      if (!success) {
        errorMessage.value = "Google session expired. Please try again.";
        return;
      }
      // Retry after re-auth
      result = await listMessages({
        q: searchQuery.value,
        maxResults: 20,
      });
    }

    if (result && result.messages) {
      // Fetch full message details
      const fullMessages = await Promise.all(
        result.messages.map((m) => getMessage(m.id)),
      );
      messages.value = fullMessages.filter(
        (m): m is GmailMessage => m !== null,
      );
      nextPageToken.value = result.nextPageToken;
    }
  } catch (err) {
    errorMessage.value =
      err instanceof Error ? err.message : "Failed to search messages";
  } finally {
    isSearching.value = false;
  }
};

const loadMoreMessages = async () => {
  if (!nextPageToken.value || isLoadingMore.value) return;

  isLoadingMore.value = true;

  try {
    let result = await listMessages({
      q: lastSearchQuery.value,
      maxResults: 20,
      pageToken: nextPageToken.value,
    });

    // Handle re-authentication if needed
    if (needsReauth.value) {
      const success = await requestGoogleToken();
      if (!success) {
        errorMessage.value = "Google session expired. Please try again.";
        return;
      }
      // Retry after re-auth
      result = await listMessages({
        q: lastSearchQuery.value,
        maxResults: 20,
        pageToken: nextPageToken.value,
      });
    }

    if (result && result.messages) {
      const fullMessages = await Promise.all(
        result.messages.map((m) => getMessage(m.id)),
      );
      messages.value = [
        ...messages.value,
        ...fullMessages.filter((m): m is GmailMessage => m !== null),
      ];
      nextPageToken.value = result.nextPageToken;
    }
  } catch (err) {
    errorMessage.value =
      err instanceof Error ? err.message : "Failed to load more messages";
  } finally {
    isLoadingMore.value = false;
  }
};

const toggleThreadSelection = (threadId: string) => {
  const index = selectedThreadIds.value.indexOf(threadId);
  if (index === -1) {
    selectedThreadIds.value = [...selectedThreadIds.value, threadId];
  } else {
    selectedThreadIds.value = selectedThreadIds.value.filter(
      (id) => id !== threadId,
    );
  }
};

const removeThreadId = (threadId: string) => {
  selectedThreadIds.value = selectedThreadIds.value.filter(
    (id) => id !== threadId,
  );
};

const handleGoogleSignIn = async () => {
  try {
    await signInWithGoogle();
  } catch (err) {
    errorMessage.value =
      err instanceof Error ? err.message : "Failed to connect to Google";
  }
};

const handleCancel = () => {
  isOpen.value = false;
};

const handleSave = () => {
  emit("save", selectedThreadIds.value);
  isOpen.value = false;
};

// Reset state when dialog opens
watch(
  () => props.open,
  (newOpen) => {
    if (newOpen) {
      searchQuery.value = props.defaultSearchQuery || "";
      selectedThreadIds.value = [...(props.initialThreadIds || [])];
      hasSearched.value = false;
      messages.value = [];
      errorMessage.value = null;

      // Auto-search if we have a default query
      if (props.defaultSearchQuery && isGoogleConnected.value) {
        searchMessages();
      }
    }
  },
);

// Update search query when default changes
watch(
  () => props.defaultSearchQuery,
  (newQuery) => {
    if (props.open && newQuery) {
      searchQuery.value = newQuery;
    }
  },
);
</script>
