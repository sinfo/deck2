<template>
  <div class="container mx-auto px-4 py-6 max-w-6xl">
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <div class="space-y-2">
          <h1 class="text-3xl font-bold">Gmail Threads</h1>
          <p class="text-muted-foreground">
            Browse and explore your email threads.
          </p>
        </div>
        <div class="flex gap-2">
          <Button
            v-if="!authStore.isGoogleAuthenticated"
            :disabled="isSigningIn"
            @click="handleSignIn"
          >
            <span v-if="isSigningIn">Signing in...</span>
            <span v-else>Sign in with Google</span>
          </Button>
          <Button
            v-else
            variant="outline"
            :disabled="isLoading"
            @click="fetchThreads"
          >
            <RefreshCw
              class="w-4 h-4 mr-2"
              :class="{ 'animate-spin': isLoading }"
            />
            Refresh
          </Button>
        </div>
      </div>

      <!-- Search -->
      <div class="flex gap-2">
        <div class="flex-1">
          <Input
            v-model="searchQuery"
            placeholder="Search threads (Gmail search syntax supported)..."
            @keyup.enter="fetchThreads"
          />
        </div>
        <Button
          :disabled="isLoading || !authStore.isGoogleAuthenticated"
          @click="fetchThreads"
        >
          <Search class="w-4 h-4" />
        </Button>
        <TooltipProvider>
          <Tooltip>
            <TooltipTrigger as-child>
              <Button
                :variant="hideLinked ? 'default' : 'outline'"
                :disabled="!authStore.isGoogleAuthenticated"
                @click="hideLinked = !hideLinked"
              >
                <EyeOff v-if="hideLinked" class="w-4 h-4" />
                <Eye v-else class="w-4 h-4" />
              </Button>
            </TooltipTrigger>
            <TooltipContent>
              {{ hideLinked ? "Show linked threads" : "Hide linked threads" }}
            </TooltipContent>
          </Tooltip>
        </TooltipProvider>
      </div>

      <!-- Not authenticated -->
      <Card v-if="!authStore.isGoogleAuthenticated">
        <CardContent class="flex flex-col items-center justify-center py-12">
          <Mail class="w-12 h-12 text-muted-foreground mb-4" />
          <h3 class="text-lg font-semibold mb-2">Connect your Gmail account</h3>
          <p class="text-muted-foreground text-center mb-4">
            Sign in with Google to view your email threads.
          </p>
          <Button :disabled="isSigningIn" @click="handleSignIn">
            Sign in with Google
          </Button>
        </CardContent>
      </Card>

      <!-- Loading State -->
      <div
        v-else-if="isLoading && threads.length === 0"
        class="flex justify-center py-8"
      >
        <div
          class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"
        ></div>
      </div>

      <!-- Error State -->
      <Card v-else-if="error">
        <CardContent class="flex flex-col items-center justify-center py-12">
          <AlertCircle class="w-12 h-12 text-destructive mb-4" />
          <h3 class="text-lg font-semibold mb-2">Failed to load threads</h3>
          <p class="text-muted-foreground text-center mb-4">{{ error }}</p>
          <Button variant="outline" @click="fetchThreads">Try Again</Button>
        </CardContent>
      </Card>

      <!-- Threads List -->
      <div v-else-if="threads.length > 0" class="space-y-4">
        <div class="text-sm text-muted-foreground">
          Showing {{ filteredThreads.length }} threads
          <span v-if="hideLinked && threads.length !== filteredThreads.length">
            ({{ threads.length - filteredThreads.length }} linked hidden)
          </span>
          <span v-if="nextPageToken"> (more available)</span>
        </div>

        <div class="space-y-2">
          <Collapsible
            v-for="thread in filteredThreads"
            :key="thread.id"
            v-model:open="expandedThreads[thread.id]"
            class="border rounded-lg"
          >
            <Card class="border-0 shadow-none">
              <CardContent class="py-4">
                <div class="flex items-start justify-between gap-4">
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-2 mb-1">
                      <span class="font-semibold truncate">
                        {{
                          getThreadParticipants(thread) ||
                          "Unknown participants"
                        }}
                      </span>
                      <Badge variant="outline" class="text-xs">
                        {{ thread.messages.length }}
                        {{
                          thread.messages.length === 1 ? "message" : "messages"
                        }}
                      </Badge>
                      <span
                        class="text-xs text-muted-foreground whitespace-nowrap"
                      >
                        {{ formatDate(getLatestMessage(thread).internalDate) }}
                      </span>
                    </div>
                    <div class="font-medium truncate mb-1">
                      {{ getThreadSubject(thread) || "(no subject)" }}
                    </div>
                    <div class="text-sm text-muted-foreground truncate">
                      {{ getLatestMessage(thread).snippet }}
                    </div>
                  </div>
                  <div class="flex items-center gap-2">
                    <template v-if="isThreadLinked(thread.id)">
                      <div
                        class="flex items-center gap-2 px-2 py-1 rounded-md bg-muted cursor-pointer hover:bg-muted/80 transition-colors"
                        @click.stop="navigateToEntity(thread.id)"
                      >
                        <img
                          v-if="getLinkedEntityDetails(thread.id)?.entityImage"
                          :src="getLinkedEntityDetails(thread.id)?.entityImage"
                          :alt="getLinkedEntityName(thread.id) || 'Entity'"
                          class="w-5 h-5 rounded-full object-cover"
                        />
                        <div
                          v-else
                          class="w-5 h-5 rounded-full bg-primary/10 flex items-center justify-center"
                        >
                          <Building
                            v-if="
                              getLinkedEntityDetails(thread.id)?.entityType ===
                              'company'
                            "
                            class="w-3 h-3 text-primary"
                          />
                          <User v-else class="w-3 h-3 text-primary" />
                        </div>
                        <span class="text-xs font-medium truncate max-w-24">
                          {{ getLinkedEntityName(thread.id) }}
                        </span>
                      </div>
                    </template>
                    <div class="flex gap-1">
                      <Badge
                        v-for="label in getThreadLabels(thread)"
                        :key="label"
                        variant="secondary"
                        class="text-xs"
                      >
                        {{ label }}
                      </Badge>
                    </div>
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger as-child>
                          <Button
                            variant="ghost"
                            size="icon"
                            class="h-8 w-8"
                            @click.stop="openLinkDialog(thread)"
                          >
                            <Link2 class="w-4 h-4" />
                          </Button>
                        </TooltipTrigger>
                        <TooltipContent>
                          Link to company/speaker
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                    <CollapsibleTrigger as-child>
                      <Button variant="ghost" size="icon" class="h-8 w-8">
                        <ChevronDown
                          class="w-4 h-4 transition-transform"
                          :class="{
                            'rotate-180': expandedThreads[thread.id],
                          }"
                        />
                      </Button>
                    </CollapsibleTrigger>
                  </div>
                </div>
              </CardContent>
            </Card>

            <!-- Expanded Messages -->
            <CollapsibleContent>
              <div class="border-t px-4 py-2 space-y-3 bg-muted/30">
                <div
                  v-for="(message, index) in thread.messages"
                  :key="message.id"
                  class="p-3 bg-background rounded-md border cursor-pointer hover:bg-accent/50 transition-colors"
                  @click="selectMessage(message)"
                >
                  <div class="flex items-start justify-between gap-2 mb-1">
                    <div class="flex items-center gap-2">
                      <span class="font-medium text-sm">
                        {{ getHeaderValue(message, "From") || "Unknown" }}
                      </span>
                      <span v-if="index === thread.messages.length - 1">
                        <Badge variant="outline" class="text-xs">Latest</Badge>
                      </span>
                    </div>
                    <span class="text-xs text-muted-foreground">
                      {{ formatDate(message.internalDate, true) }}
                    </span>
                  </div>
                  <div class="text-sm text-muted-foreground truncate">
                    {{ message.snippet }}
                  </div>
                </div>
              </div>
            </CollapsibleContent>
          </Collapsible>
        </div>

        <!-- Load More -->
        <div v-if="nextPageToken" class="flex justify-center">
          <Button variant="outline" :disabled="isLoading" @click="loadMore">
            <span v-if="isLoading">Loading...</span>
            <span v-else>Load More</span>
          </Button>
        </div>
      </div>

      <!-- Empty State -->
      <Card v-else-if="authStore.isGoogleAuthenticated && !isLoading">
        <CardContent class="flex flex-col items-center justify-center py-12">
          <Inbox class="w-12 h-12 text-muted-foreground mb-4" />
          <h3 class="text-lg font-semibold mb-2">No threads found</h3>
          <p class="text-muted-foreground text-center">
            {{
              searchQuery
                ? "Try a different search query."
                : "Your inbox is empty."
            }}
          </p>
        </CardContent>
      </Card>

      <!-- Message Detail Sheet -->
      <Sheet v-model:open="isDetailOpen">
        <SheetContent class="w-full sm:max-w-2xl overflow-y-auto">
          <SheetHeader>
            <SheetTitle class="text-left">
              {{
                selectedMessage
                  ? getHeaderValue(selectedMessage, "Subject") || "(no subject)"
                  : ""
              }}
            </SheetTitle>
            <SheetDescription class="text-left">
              <div v-if="selectedMessage" class="space-y-2 mt-2">
                <div>
                  <strong>From:</strong>
                  {{ getHeaderValue(selectedMessage, "From") }}
                </div>
                <div>
                  <strong>To:</strong>
                  {{ getHeaderValue(selectedMessage, "To") }}
                </div>
                <div v-if="getHeaderValue(selectedMessage, 'Cc')">
                  <strong>Cc:</strong>
                  {{ getHeaderValue(selectedMessage, "Cc") }}
                </div>
                <div>
                  <strong>Date:</strong>
                  {{ formatDate(selectedMessage.internalDate, true) }}
                </div>
              </div>
            </SheetDescription>
          </SheetHeader>
          <Separator class="my-4" />
          <div
            v-if="selectedMessageBody"
            class="prose prose-sm dark:prose-invert max-w-none"
          >
            <div v-if="isHtmlBody" v-html="selectedMessageBody"></div>
            <pre v-else class="whitespace-pre-wrap text-sm">{{
              selectedMessageBody
            }}</pre>
          </div>
          <div v-else-if="isLoadingBody" class="flex justify-center py-8">
            <div
              class="animate-spin rounded-full h-6 w-6 border-b-2 border-primary"
            ></div>
          </div>
        </SheetContent>
      </Sheet>

      <!-- Link Dialog -->
      <AlertDialog v-model:open="isLinkDialogOpen">
        <AlertDialogContent class="max-w-lg">
          <AlertDialogHeader>
            <AlertDialogTitle>Link Gmail Thread</AlertDialogTitle>
            <AlertDialogDescription>
              Select a company or speaker to link this Gmail thread to their
              communications.
            </AlertDialogDescription>
          </AlertDialogHeader>

          <div class="space-y-4 py-4">
            <!-- Entity Type Selection -->
            <div class="flex gap-2">
              <Button
                :variant="linkEntityType === 'company' ? 'default' : 'outline'"
                class="flex-1"
                @click="linkEntityType = 'company'"
              >
                <Building class="w-4 h-4 mr-2" />
                Company
              </Button>
              <Button
                :variant="linkEntityType === 'speaker' ? 'default' : 'outline'"
                class="flex-1"
                @click="linkEntityType = 'speaker'"
              >
                <User class="w-4 h-4 mr-2" />
                Speaker
              </Button>
            </div>

            <!-- Search Input -->
            <div class="space-y-2">
              <Input
                v-model="linkSearchQuery"
                :placeholder="`Search ${linkEntityType}s...`"
                @input="debouncedSearch"
              />
            </div>

            <!-- Results List -->
            <div v-if="isSearchingEntities" class="flex justify-center py-4">
              <div
                class="animate-spin rounded-full h-6 w-6 border-b-2 border-primary"
              ></div>
            </div>
            <div
              v-else-if="linkSearchResults.length > 0"
              class="max-h-60 overflow-y-auto space-y-1"
            >
              <div
                v-for="entity in linkSearchResults"
                :key="entity.id"
                class="flex items-center justify-between p-2 rounded-md hover:bg-accent cursor-pointer"
                :class="{
                  'bg-accent': selectedLinkEntity?.id === entity.id,
                }"
                @click="selectedLinkEntity = entity"
              >
                <div class="flex items-center gap-2">
                  <div
                    class="w-8 h-8 rounded-full bg-muted flex items-center justify-center"
                  >
                    <Building
                      v-if="linkEntityType === 'company'"
                      class="w-4 h-4"
                    />
                    <User v-else class="w-4 h-4" />
                  </div>
                  <div>
                    <div class="font-medium">{{ entity.name }}</div>
                    <div
                      v-if="entity.participation"
                      class="text-xs text-muted-foreground"
                    >
                      Event {{ entity.participation.event }}
                    </div>
                  </div>
                </div>
                <Badge
                  v-if="
                    entity.participation?.gmailThreadIds?.includes(
                      threadToLink?.id || '',
                    )
                  "
                  variant="secondary"
                >
                  Already linked
                </Badge>
              </div>
            </div>
            <div
              v-else-if="linkSearchQuery && !isSearchingEntities"
              class="text-center py-4 text-muted-foreground"
            >
              No {{ linkEntityType }}s found
            </div>
            <div v-else class="text-center py-4 text-muted-foreground">
              Start typing to search for {{ linkEntityType }}s
            </div>
          </div>

          <AlertDialogFooter>
            <AlertDialogCancel @click="closeLinkDialog">
              Cancel
            </AlertDialogCancel>
            <Button
              :disabled="!selectedLinkEntity || isLinking"
              @click="linkThread"
            >
              <span v-if="isLinking">Linking...</span>
              <span v-else>Link Thread</span>
            </Button>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted, reactive, computed } from "vue";
import { useRouter } from "vue-router";
import { useAuthStore } from "@/stores/auth";
import { useEventStore } from "@/stores/event";
import { useGoogleAuth } from "@/composables/useGoogleAuth";
import {
  useGmailMessages,
  type GmailMessage,
  type GmailThread,
} from "@/composables/useGmailMessages";
import {
  getAllCompanies,
  updateCompanyGmailThreadIds,
  syncCompanyGmailMessages,
  type GmailMessageData,
} from "@/api/companies";
import {
  getAllSpeakers,
  updateSpeakerGmailThreadIds,
  syncSpeakerGmailMessages,
} from "@/api/speakers";
import {
  getLinkedGmailThreads,
  type LinkedGmailThreadInfo,
} from "@/api/events";
import type { CompanyWithParticipation } from "@/dto/companies";
import type { SpeakerWithParticipation } from "@/dto/speakers";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import {
  AlertDialog,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import {
  RefreshCw,
  Search,
  Mail,
  AlertCircle,
  Inbox,
  Link2,
  Building,
  User,
  ChevronDown,
  Eye,
  EyeOff,
} from "lucide-vue-next";

const authStore = useAuthStore();
const eventStore = useEventStore();
const router = useRouter();
const { signInWithGoogle, isSigningIn, requestGoogleToken } = useGoogleAuth();
const {
  listThreads,
  getThreads,
  getMessage,
  getHeaderValue,
  getMessageBody,
  isLoading,
  error,
  needsReauth,
} = useGmailMessages();

const searchQuery = ref("");
const threads = ref<GmailThread[]>([]);
const nextPageToken = ref<string | undefined>();
const expandedThreads = reactive<Record<string, boolean>>({});

const selectedMessage = ref<GmailMessage | null>(null);
const selectedMessageBody = ref<string | null>(null);
const isDetailOpen = ref(false);
const isLoadingBody = ref(false);
const isHtmlBody = ref(false);

// Link dialog state
const isLinkDialogOpen = ref(false);
const threadToLink = ref<GmailThread | null>(null);
const linkEntityType = ref<"company" | "speaker">("company");
const linkSearchQuery = ref("");
const linkSearchResults = ref<
  (CompanyWithParticipation | SpeakerWithParticipation)[]
>([]);
const selectedLinkEntity = ref<
  CompanyWithParticipation | SpeakerWithParticipation | null
>(null);
const isSearchingEntities = ref(false);
const isLinking = ref(false);

// Track linked thread IDs across all entities
const linkedThreadIds = ref<Set<string>>(new Set());
const linkedThreadDetails = ref<Map<string, LinkedGmailThreadInfo>>(new Map());
const hideLinked = ref(false);

const handleSignIn = async () => {
  const success = await signInWithGoogle();
  if (success) {
    await fetchLinkedThreadIds();
    await fetchThreads();
  }
};

const fetchThreads = async () => {
  let result = await listThreads({
    maxResults: 20,
    q: searchQuery.value || undefined,
  });

  // Handle re-auth if needed
  if (needsReauth.value) {
    const success = await requestGoogleToken();
    if (success) {
      result = await listThreads({
        maxResults: 20,
        q: searchQuery.value || undefined,
      });
    }
  }

  if (result && result.threads) {
    // Fetch all thread details in parallel
    const fullThreads = await getThreads(
      result.threads.map((t) => t.id),
      {
        format: "metadata",
        metadataHeaders: ["From", "To", "Subject", "Cc", "Date"],
      },
    );
    threads.value = fullThreads;
    nextPageToken.value = result.nextPageToken;
  }
};

const loadMore = async () => {
  if (!nextPageToken.value) return;

  const result = await listThreads({
    maxResults: 20,
    q: searchQuery.value || undefined,
    pageToken: nextPageToken.value,
  });

  if (result && result.threads) {
    // Fetch all thread details in parallel
    const fullThreads = await getThreads(
      result.threads.map((t) => t.id),
      {
        format: "metadata",
        metadataHeaders: ["From", "To", "Subject", "Cc", "Date"],
      },
    );
    threads.value = [...threads.value, ...fullThreads];
    nextPageToken.value = result.nextPageToken;
  }
};

const selectMessage = async (message: GmailMessage) => {
  selectedMessage.value = message;
  selectedMessageBody.value = null;
  isDetailOpen.value = true;
  isLoadingBody.value = true;

  // Fetch full message content
  const fullMessage = await getMessage(message.id, { format: "full" });
  if (fullMessage) {
    selectedMessage.value = fullMessage;
    const body = getMessageBody(fullMessage, true);
    selectedMessageBody.value = body;
    isHtmlBody.value = (body?.includes("<") && body?.includes(">")) || false;
  }
  isLoadingBody.value = false;
};

const formatDate = (internalDate: string, full = false) => {
  const date = new Date(parseInt(internalDate));
  if (full) {
    return date.toLocaleString();
  }
  const now = new Date();
  const isToday = date.toDateString() === now.toDateString();
  if (isToday) {
    return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  }
  return date.toLocaleDateString([], { month: "short", day: "numeric" });
};

const getLatestMessage = (thread: GmailThread): GmailMessage => {
  return thread.messages[thread.messages.length - 1];
};

const getThreadSubject = (thread: GmailThread): string | undefined => {
  // Get subject from first message
  const firstMessage = thread.messages[0];
  return getHeaderValue(firstMessage, "Subject");
};

const getThreadParticipants = (thread: GmailThread): string => {
  const participants = new Set<string>();
  for (const msg of thread.messages) {
    const from = getHeaderValue(msg, "From");
    if (from) {
      // Extract name or email
      const match = from.match(/^"?([^"<]+)"?\s*<?/);
      const name = match ? match[1].trim() : from.split("@")[0];
      participants.add(name);
    }
  }
  return Array.from(participants).slice(0, 3).join(", ");
};

const getThreadLabels = (thread: GmailThread): string[] => {
  const displayLabels = ["STARRED", "UNREAD"];
  const labels = new Set<string>();
  for (const msg of thread.messages) {
    if (msg.labelIds) {
      for (const labelId of msg.labelIds) {
        if (displayLabels.includes(labelId)) {
          labels.add(labelId.charAt(0) + labelId.slice(1).toLowerCase());
        }
      }
    }
  }
  return Array.from(labels);
};

// Fetch all linked thread IDs from the backend
const fetchLinkedThreadIds = async () => {
  try {
    const eventId = eventStore.selectedEvent?.id;
    if (!eventId) {
      console.warn("No event selected, cannot fetch linked threads");
      return;
    }

    const response = await getLinkedGmailThreads(eventId);

    // Update the set of linked thread IDs
    linkedThreadIds.value = new Set(response.data.threadIds);

    // Store the details for each thread
    linkedThreadDetails.value = new Map(
      response.data.details.map((detail) => [detail.threadId, detail]),
    );
  } catch (err) {
    console.error("Failed to fetch linked thread IDs:", err);
  }
};

const isThreadLinked = (threadId: string) => {
  return linkedThreadIds.value.has(threadId);
};

const getLinkedEntityDetails = (threadId: string) => {
  return linkedThreadDetails.value.get(threadId) || null;
};

const getLinkedEntityName = (threadId: string) => {
  const detail = linkedThreadDetails.value.get(threadId);
  return detail ? detail.entityName : null;
};

const navigateToEntity = (threadId: string) => {
  const detail = linkedThreadDetails.value.get(threadId);
  if (!detail) return;

  if (detail.entityType === "company") {
    router.push({ name: "company", params: { companyId: detail.entityId } });
  } else {
    router.push({ name: "speaker", params: { speakerId: detail.entityId } });
  }
};

const filteredThreads = computed(() => {
  if (!hideLinked.value) return threads.value;
  return threads.value.filter((thread) => !isThreadLinked(thread.id));
});

// Link dialog functions
const openLinkDialog = (thread: GmailThread) => {
  threadToLink.value = thread;
  linkSearchQuery.value = "";
  linkSearchResults.value = [];
  selectedLinkEntity.value = null;
  isLinkDialogOpen.value = true;
};

const closeLinkDialog = () => {
  isLinkDialogOpen.value = false;
  threadToLink.value = null;
  linkSearchQuery.value = "";
  linkSearchResults.value = [];
  selectedLinkEntity.value = null;
};

let searchTimeout: ReturnType<typeof setTimeout> | null = null;
const debouncedSearch = () => {
  if (searchTimeout) {
    clearTimeout(searchTimeout);
  }
  searchTimeout = setTimeout(() => {
    searchEntities();
  }, 300);
};

const searchEntities = async () => {
  if (!linkSearchQuery.value.trim()) {
    linkSearchResults.value = [];
    return;
  }

  isSearchingEntities.value = true;

  try {
    const eventId = eventStore.selectedEvent?.id;

    if (linkEntityType.value === "company") {
      const response = await getAllCompanies({
        name: linkSearchQuery.value,
        event: eventId,
      });
      // When filtered by event, companies have participation field
      linkSearchResults.value =
        response.data as unknown as CompanyWithParticipation[];
    } else {
      const response = await getAllSpeakers({
        name: linkSearchQuery.value,
        event: eventId,
      });
      // When filtered by event, speakers have participation field
      linkSearchResults.value =
        response.data as unknown as SpeakerWithParticipation[];
    }
  } catch (err) {
    console.error("Failed to search entities:", err);
    linkSearchResults.value = [];
  } finally {
    isSearchingEntities.value = false;
  }
};

// Reset search when entity type changes
watch(linkEntityType, () => {
  linkSearchResults.value = [];
  selectedLinkEntity.value = null;
  if (linkSearchQuery.value) {
    searchEntities();
  }
});

/**
 * Strips HTML tags and converts to clean plain text
 */
const stripHtmlToText = (html: string): string => {
  const doc = new DOMParser().parseFromString(html, "text/html");
  doc.querySelectorAll("script, style").forEach((el) => el.remove());
  doc.querySelectorAll("br").forEach((el) => el.replaceWith("\n"));
  doc.querySelectorAll("p, div, tr, li").forEach((el) => {
    el.prepend(document.createTextNode("\n"));
    el.append(document.createTextNode("\n"));
  });

  let text = doc.body.textContent || "";
  text = text
    .replace(/\r\n/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .replace(/[ \t]+/g, " ")
    .replace(/^ +/gm, "")
    .replace(/ +$/gm, "")
    .trim();

  return text;
};

/**
 * Extracts a clean display name from an email address
 */
const extractEmailName = (email: string): string => {
  const match = email.match(/^"?([^"<]+)"?\s*<[^>]+>$/);
  return match ? match[1].trim() : email;
};

const linkThread = async () => {
  if (!selectedLinkEntity.value || !threadToLink.value) return;

  isLinking.value = true;

  try {
    const entity = selectedLinkEntity.value;
    const threadId = threadToLink.value.id;

    // Get current Gmail thread IDs
    const currentThreadIds = entity.participation?.gmailThreadIds || [];

    // Add the new thread ID if not already linked
    if (!currentThreadIds.includes(threadId)) {
      const newThreadIds = [...currentThreadIds, threadId];

      // Update the participation's Gmail thread IDs
      if (linkEntityType.value === "company") {
        await updateCompanyGmailThreadIds(entity.id, newThreadIds);
      } else {
        await updateSpeakerGmailThreadIds(entity.id, newThreadIds);
      }

      // Sync the messages from this thread
      await syncThreadMessages(entity.id, threadToLink.value);

      // Update local linked IDs and details
      linkedThreadIds.value.add(threadId);
      linkedThreadDetails.value.set(threadId, {
        threadId,
        entityType: linkEntityType.value,
        entityId: entity.id,
        entityName: entity.name,
      });
    }

    closeLinkDialog();
  } catch (err) {
    console.error("Failed to link thread:", err);
  } finally {
    isLinking.value = false;
  }
};

const syncThreadMessages = async (entityId: string, thread: GmailThread) => {
  try {
    const allMessages: GmailMessageData[] = [];

    for (const msg of thread.messages) {
      const from = getHeaderValue(msg, "From") || "Unknown";
      const to = getHeaderValue(msg, "To") || "";
      const subject = getHeaderValue(msg, "Subject") || "(No subject)";
      const dateStr = getHeaderValue(msg, "Date") || "";

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

      let body = getMessageBody(msg, false) || msg.snippet || "";
      if (body.includes("<") && body.includes(">")) {
        body = stripHtmlToText(body);
      }

      // Clean up quoted content
      const lines = body.split("\n");
      const cleanedLines: string[] = [];
      let foundQuoteStart = false;

      for (const line of lines) {
        if (
          line.match(/^On\s+.+\s+wrote:?\s*$/i) ||
          line.match(/^On\s+\w{3},?\s+\w{3}\s+\d{1,2},?\s+\d{4}/i) ||
          line.match(/^On\s+\w{3},?\s+\d{1,2}\s+\w{3}/i) ||
          line.match(/^On\s+\d{1,2}\s+\w{3}\s+\d{4}/i) ||
          line.match(/wrote:\s*$/) ||
          line.match(/^>/) ||
          line.match(/^-{3,}\s*Original Message\s*-{3,}$/i) ||
          line.match(/^_{3,}$/) ||
          line.match(/^From:.*Sent:.*To:/i) ||
          line.match(/^-{2,}\s*Forwarded message\s*-{2,}$/i) ||
          line.match(/<[^>]+@[^>]+>\s*wrote:?\s*$/i)
        ) {
          foundQuoteStart = true;
        }
        if (!foundQuoteStart) {
          cleanedLines.push(line);
        }
      }

      const cleanBody =
        cleanedLines.length > 0 ? cleanedLines.join("\n").trim() : body;

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

    if (allMessages.length > 0) {
      if (linkEntityType.value === "company") {
        await syncCompanyGmailMessages(entityId, allMessages);
      } else {
        await syncSpeakerGmailMessages(entityId, allMessages);
      }
    }
  } catch (err) {
    console.error("Failed to sync thread messages:", err);
  }
};

// Auto-fetch on mount if authenticated
onMounted(async () => {
  if (authStore.isGoogleAuthenticated) {
    // Fetch linked thread IDs first, then fetch threads
    await fetchLinkedThreadIds();
    await fetchThreads();
  }
});

// Watch for event changes to re-fetch linked threads
watch(
  () => eventStore.selectedEvent?.id,
  async (newEventId) => {
    if (newEventId && authStore.isGoogleAuthenticated) {
      await fetchLinkedThreadIds();
    }
  },
);
</script>
