<template>
  <div class="container mx-auto px-4 py-6 max-w-6xl">
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <div class="space-y-2">
          <h1 class="text-3xl font-bold">Gmail Messages</h1>
          <p class="text-muted-foreground">
            Browse and explore your email messages.
          </p>
        </div>
        <div class="flex gap-2">
          <Button
            v-if="!authStore.googleAccessToken"
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
            @click="fetchMessages"
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
            placeholder="Search messages (Gmail search syntax supported)..."
            @click="fetchMessages"
          />
        </div>
        <Button
          :disabled="isLoading || !authStore.googleAccessToken"
          @click="fetchMessages"
        >
          <Search class="w-4 h-4" />
        </Button>
      </div>

      <!-- Not authenticated -->
      <Card v-if="!authStore.googleAccessToken">
        <CardContent class="flex flex-col items-center justify-center py-12">
          <Mail class="w-12 h-12 text-muted-foreground mb-4" />
          <h3 class="text-lg font-semibold mb-2">Connect your Gmail account</h3>
          <p class="text-muted-foreground text-center mb-4">
            Sign in with Google to view your email messages.
          </p>
          <Button :disabled="isSigningIn" @click="handleSignIn">
            Sign in with Google
          </Button>
        </CardContent>
      </Card>

      <!-- Loading State -->
      <div
        v-else-if="isLoading && messages.length === 0"
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
          <h3 class="text-lg font-semibold mb-2">Failed to load messages</h3>
          <p class="text-muted-foreground text-center mb-4">{{ error }}</p>
          <Button variant="outline" @click="fetchMessages">Try Again</Button>
        </CardContent>
      </Card>

      <!-- Messages List -->
      <div v-else-if="messages.length > 0" class="space-y-4">
        <div class="text-sm text-muted-foreground">
          Showing {{ messages.length }} messages
          <span v-if="nextPageToken"> (more available)</span>
        </div>

        <div class="space-y-2">
          <Card
            v-for="message in messages"
            :key="message.id"
            class="cursor-pointer hover:bg-accent/50 transition-colors"
            @click="selectMessage(message)"
          >
            <CardContent class="py-4">
              <div class="flex items-start justify-between gap-4">
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2 mb-1">
                    <span class="font-semibold truncate">
                      {{ getHeaderValue(message, "From") || "Unknown sender" }}
                    </span>
                    <span
                      class="text-xs text-muted-foreground whitespace-nowrap"
                    >
                      {{ formatDate(message.internalDate) }}
                    </span>
                  </div>
                  <div class="font-medium truncate mb-1">
                    {{ getHeaderValue(message, "Subject") || "(no subject)" }}
                  </div>
                  <div class="text-sm text-muted-foreground truncate">
                    {{ message.snippet }}
                  </div>
                </div>
                <div class="flex gap-1">
                  <Badge
                    v-for="label in getDisplayLabels(message.labelIds)"
                    :key="label"
                    variant="secondary"
                    class="text-xs"
                  >
                    {{ label }}
                  </Badge>
                </div>
              </div>
            </CardContent>
          </Card>
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
      <Card v-else-if="authStore.googleAccessToken && !isLoading">
        <CardContent class="flex flex-col items-center justify-center py-12">
          <Inbox class="w-12 h-12 text-muted-foreground mb-4" />
          <h3 class="text-lg font-semibold mb-2">No messages found</h3>
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
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
import { useAuthStore } from "@/stores/auth";
import { useGoogleAuth } from "@/composables/useGoogleAuth";
import {
  useGmailMessages,
  type GmailMessage,
} from "@/composables/useGmailMessages";
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
import { RefreshCw, Search, Mail, AlertCircle, Inbox } from "lucide-vue-next";

const authStore = useAuthStore();
const { signInWithGoogle, isSigningIn } = useGoogleAuth();
const {
  listMessages,
  getMessage,
  getMessages,
  getHeaderValue,
  getMessageBody,
  isLoading,
  error,
} = useGmailMessages();

const searchQuery = ref("");
const messages = ref<GmailMessage[]>([]);
const nextPageToken = ref<string | undefined>();

const selectedMessage = ref<GmailMessage | null>(null);
const selectedMessageBody = ref<string | null>(null);
const isDetailOpen = ref(false);
const isLoadingBody = ref(false);
const isHtmlBody = ref(false);

const handleSignIn = async () => {
  const success = await signInWithGoogle();
  if (success) {
    await fetchMessages();
  }
};

const fetchMessages = async () => {
  const result = await listMessages({
    maxResults: 20,
    q: searchQuery.value || undefined,
  });

  if (result && result.messages) {
    // Fetch all message details in parallel
    const fullMessages = await getMessages(
      result.messages.map((m) => m.id),
      {
        format: "metadata",
        metadataHeaders: ["From", "To", "Subject", "Cc", "Date"],
      },
    );
    messages.value = fullMessages;
    nextPageToken.value = result.nextPageToken;
  }
};

const loadMore = async () => {
  if (!nextPageToken.value) return;

  const result = await listMessages({
    maxResults: 20,
    q: searchQuery.value || undefined,
    pageToken: nextPageToken.value,
  });

  if (result && result.messages) {
    // Fetch all message details in parallel
    const fullMessages = await getMessages(
      result.messages.map((m) => m.id),
      {
        format: "metadata",
        metadataHeaders: ["From", "To", "Subject", "Cc", "Date"],
      },
    );
    messages.value = [...messages.value, ...fullMessages];
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

const getDisplayLabels = (labelIds?: string[]) => {
  if (!labelIds) return [];
  const displayLabels = ["IMPORTANT", "STARRED", "UNREAD"];
  return labelIds
    .filter((id) => displayLabels.includes(id))
    .map((id) => id.charAt(0) + id.slice(1).toLowerCase());
};

// Auto-fetch messages if already authenticated
if (authStore.googleAccessToken) {
  fetchMessages();
}
</script>
