<template>
  <div class="container mx-auto px-4 py-6 max-w-4xl">
    <div class="space-y-6">
      <!-- Header -->
      <div class="space-y-2">
        <h1 class="text-3xl font-bold">Settings</h1>
        <p class="text-muted-foreground">
          Manage your personal information and contact details.
        </p>
      </div>

      <!-- Loading State -->
      <div v-if="isLoading" class="flex justify-center py-8">
        <div
          class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"
        ></div>
      </div>

      <!-- Error State -->
      <div v-else-if="error" class="text-center py-8">
        <p class="text-destructive">Failed to load user information</p>
        <Button variant="outline" class="mt-2" @click="refetch">
          Try Again
        </Button>
      </div>

      <!-- Settings Content -->
      <div v-else-if="user" class="space-y-6">
        <Tabs default-value="profile" class="space-y-6">
          <TabsList class="grid w-full max-w-xs grid-cols-2">
            <TabsTrigger value="profile">Profile</TabsTrigger>
            <TabsTrigger value="applications">Applications</TabsTrigger>
          </TabsList>

          <TabsContent value="profile" class="space-y-6">
            <!-- Personal Information Card -->
            <Card>
              <CardHeader>
                <CardTitle>Personal Information</CardTitle>
                <CardDescription>
                  Basic information about your account
                </CardDescription>
              </CardHeader>
              <CardContent class="space-y-4">
                <div class="flex items-center space-x-4">
                  <img
                    :src="user.data.img"
                    :alt="user.data.name"
                    class="w-16 h-16 rounded-full object-cover border-2 border-border"
                    @error="handleImageError"
                  />
                  <div>
                    <h3 class="text-lg font-semibold">{{ user.data.name }}</h3>
                    <p class="text-sm text-muted-foreground">
                      IST ID: {{ user.data.istid }}
                    </p>
                    <p class="text-sm text-muted-foreground">
                      SINFO ID: {{ user.data.sinfoid }}
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
            <!-- Contact Information Card -->
            <Card>
              <CardHeader>
                <div class="flex items-center justify-between">
                  <div>
                    <CardTitle>Contact Information</CardTitle>
                    <CardDescription>
                      Manage your contact details and preferences
                    </CardDescription>
                  </div>
                  <Button
                    variant="outline"
                    size="sm"
                    :disabled="isSaving"
                    @click="isEditMode = !isEditMode"
                  >
                    {{ isEditMode ? "Cancel" : "Edit" }}
                  </Button>
                </div>
              </CardHeader>
              <CardContent>
                <!-- View Mode -->
                <div v-if="!isEditMode" class="space-y-4">
                  <!-- Contact Details Display -->
                  <div v-if="user.data.contactObject" class="space-y-4">
                    <!-- Gender and Language -->
                    <div class="flex gap-4">
                      <div
                        v-if="user.data.contactObject.gender"
                        class="space-y-1"
                      >
                        <Label class="text-sm font-medium text-muted-foreground"
                          >Gender</Label
                        >
                        <Badge variant="secondary" class="text-sm">
                          {{ formatGender(user.data.contactObject.gender) }}
                        </Badge>
                      </div>
                      <div
                        v-if="user.data.contactObject.language"
                        class="space-y-1"
                      >
                        <Label class="text-sm font-medium text-muted-foreground"
                          >Language</Label
                        >
                        <Badge variant="outline" class="text-sm">
                          {{ formatLanguage(user.data.contactObject.language) }}
                        </Badge>
                      </div>
                    </div>

                    <!-- Email Addresses -->
                    <div
                      v-if="user.data.contactObject.mails.length"
                      class="space-y-2"
                    >
                      <Label class="text-sm font-medium text-muted-foreground"
                        >Email Addresses</Label
                      >
                      <div class="space-y-1">
                        <div
                          v-for="mail in user.data.contactObject.mails"
                          :key="mail.mail"
                          class="flex items-center gap-2 text-sm"
                        >
                          <a
                            :href="`mailto:${mail.mail}`"
                            class="text-primary hover:underline"
                          >
                            {{ mail.mail }}
                          </a>
                          <div class="flex gap-1">
                            <Badge
                              v-if="mail.personal"
                              variant="secondary"
                              class="text-xs"
                            >
                              Personal
                            </Badge>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Phone Numbers -->
                    <div
                      v-if="user.data.contactObject.phones.length"
                      class="space-y-2"
                    >
                      <Label class="text-sm font-medium text-muted-foreground"
                        >Phone Numbers</Label
                      >
                      <div class="space-y-1">
                        <div
                          v-for="phone in user.data.contactObject.phones"
                          :key="phone.phone"
                          class="flex items-center gap-2 text-sm"
                        >
                          <a
                            :href="`tel:${phone.phone}`"
                            class="text-primary hover:underline"
                          >
                            {{ phone.phone }}
                          </a>
                        </div>
                      </div>
                    </div>

                    <!-- Social Media -->
                    <div
                      v-if="hasSocials(user.data.contactObject.socials)"
                      class="space-y-2"
                    >
                      <Label class="text-sm font-medium text-muted-foreground"
                        >Social Media</Label
                      >
                      <div class="flex flex-wrap gap-2">
                        <a
                          v-if="user.data.contactObject.socials.linkedin"
                          :href="
                            linkedinUrl(
                              user.data.contactObject.socials.linkedin,
                            )
                          "
                          target="_blank"
                          rel="noopener noreferrer"
                          class="inline-flex items-center gap-1 text-xs px-2 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition-colors"
                        >
                          LinkedIn
                        </a>
                        <a
                          v-if="user.data.contactObject.socials.twitter"
                          :href="
                            twitterUrl(user.data.contactObject.socials.twitter)
                          "
                          target="_blank"
                          rel="noopener noreferrer"
                          class="inline-flex items-center gap-1 text-xs px-2 py-1 bg-sky-100 text-sky-700 rounded hover:bg-sky-200 transition-colors"
                        >
                          Twitter
                        </a>
                        <a
                          v-if="user.data.contactObject.socials.facebook"
                          :href="
                            facebookUrl(
                              user.data.contactObject.socials.facebook,
                            )
                          "
                          target="_blank"
                          rel="noopener noreferrer"
                          class="inline-flex items-center gap-1 text-xs px-2 py-1 bg-blue-100 text-blue-800 rounded hover:bg-blue-200 transition-colors"
                        >
                          Facebook
                        </a>
                        <a
                          v-if="user.data.contactObject.socials.github"
                          :href="
                            githubUrl(user.data.contactObject.socials.github)
                          "
                          target="_blank"
                          rel="noopener noreferrer"
                          class="inline-flex items-center gap-1 text-xs px-2 py-1 bg-gray-100 text-gray-700 rounded hover:bg-gray-200 transition-colors"
                        >
                          GitHub
                        </a>
                        <a
                          v-if="user.data.contactObject.socials.skype"
                          :href="`skype:${user.data.contactObject.socials.skype}?chat`"
                          class="inline-flex items-center gap-1 text-xs px-2 py-1 bg-cyan-100 text-cyan-700 rounded hover:bg-cyan-200 transition-colors"
                        >
                          Skype
                        </a>
                      </div>
                    </div>
                  </div>

                  <!-- Empty State -->
                  <div v-else class="text-center py-8 text-muted-foreground">
                    <p>No contact information available</p>
                    <Button
                      variant="outline"
                      class="mt-2"
                      @click="isEditMode = true"
                    >
                      Add Contact Information
                    </Button>
                  </div>
                </div>

                <!-- Edit Mode -->
                <div v-if="isEditMode && user.data.contactObject">
                  <ContactForm
                    mode="edit"
                    without-name
                    :initial-data="{
                      id: user.data.contactObject.id,
                      name: user.data.name,
                      contact: user.data.contactObject,
                    }"
                    :is-loading="isSaving"
                    @submit="handleUpdateContact"
                    @cancel="isEditMode = false"
                  />
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="applications" class="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Connected Applications</CardTitle>
                <CardDescription>
                  These are the applications that you have connected to your
                  DECK account.
                </CardDescription>
              </CardHeader>
              <CardContent class="space-y-6">
                <!-- Gmail Application Item -->
                <div
                  class="flex flex-col sm:flex-row sm:items-center justify-between p-4 rounded-lg border gap-4 transition-colors"
                  :class="
                    authStore.isGoogleAuthenticated ? 'bg-card' : 'bg-muted/20'
                  "
                >
                  <div class="flex items-start gap-3.5">
                    <div
                      class="w-10 h-10 rounded-lg bg-red-500/10 text-red-600 flex items-center justify-center flex-shrink-0 mt-0.5"
                    >
                      <Mail class="w-5 h-5" />
                    </div>
                    <div class="space-y-1">
                      <div class="flex items-center gap-2">
                        <h4 class="font-semibold text-base leading-none">
                          Gmail
                        </h4>
                        <Badge
                          :variant="
                            authStore.isGoogleAuthenticated
                              ? 'default'
                              : 'secondary'
                          "
                          class="text-xs"
                          :class="
                            authStore.isGoogleAuthenticated
                              ? 'bg-emerald-600 hover:bg-emerald-600 text-white'
                              : ''
                          "
                        >
                          {{
                            authStore.isGoogleAuthenticated
                              ? isAutoLinking
                                ? "Syncing..."
                                : "Connected"
                              : "Disconnected"
                          }}
                        </Badge>
                      </div>
                      <p class="text-sm text-muted-foreground">
                        Automatically link and sync email threads with your
                        companies and speakers communications.
                      </p>
                      <p
                        v-if="userConnectedEmail"
                        class="text-xs text-muted-foreground"
                      >
                        {{
                          authStore.isGoogleAuthenticated
                            ? "Connected as"
                            : "Account:"
                        }}
                        <span class="font-medium text-foreground">{{
                          userConnectedEmail
                        }}</span>
                      </p>
                    </div>
                  </div>

                  <div
                    class="flex items-center gap-2 self-end sm:self-center flex-shrink-0"
                  >
                    <template v-if="authStore.isGoogleAuthenticated">
                      <Button
                        variant="outline"
                        size="sm"
                        class="gap-1.5"
                        :disabled="isAutoLinking"
                        @click="() => syncThreads(false)"
                      >
                        <RefreshCw
                          class="w-3.5 h-3.5"
                          :class="{ 'animate-spin': isAutoLinking }"
                        />
                        {{ isAutoLinking ? "Syncing..." : "Sync Threads" }}
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        class="text-destructive hover:bg-destructive/10"
                        :disabled="isAutoLinking"
                        @click="disconnectGoogle"
                      >
                        Disconnect
                      </Button>
                    </template>
                    <template v-else>
                      <Button
                        size="sm"
                        class="bg-red-600 hover:bg-red-700 text-white font-medium px-4"
                        :disabled="isSigningIn || isAutoLinking"
                        @click="connectGoogle"
                      >
                        {{
                          isSigningIn || isAutoLinking
                            ? "Connecting..."
                            : "Connect"
                        }}
                      </Button>
                    </template>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
import { useQuery, useMutation, useQueryCache } from "@pinia/colada";
import { getMe } from "@/api/members";
import { updateContact } from "@/api/contacts";
import type {
  ContactSocials,
  CreateContactData,
  Gender,
  Language,
} from "@/dto/contacts";
import Card from "@/components/ui/card/Card.vue";
import CardContent from "@/components/ui/card/CardContent.vue";
import CardDescription from "@/components/ui/card/CardDescription.vue";
import CardHeader from "@/components/ui/card/CardHeader.vue";
import CardTitle from "@/components/ui/card/CardTitle.vue";
import Button from "@/components/ui/button/Button.vue";
import Badge from "@/components/ui/badge/Badge.vue";
import Label from "@/components/ui/label/Label.vue";
import ContactForm from "@/components/companies/ContactForm.vue";
import { useAuthStore } from "@/stores/auth";
import type { CreateCompanyRepData } from "@/dto/companies";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Mail, RefreshCw } from "lucide-vue-next";
import { useGoogleAuth } from "@/composables/useGoogleAuth";
import { useAutoLinkGmail } from "@/composables/useAutoLinkGmail";
import { useEventStore } from "@/stores/event";
import { useToast } from "@/lib/toast";

const isEditMode = ref(false);
const queryCache = useQueryCache();
const eventStore = useEventStore();
const { toast } = useToast();
const { requestGoogleToken, isSigningIn } = useGoogleAuth();
const {
  isAutoLinking,
  autoLinkEventEntities,
  syncRecentGmailUpdates,
  warnUnlinkedContacted,
} = useAutoLinkGmail();

// Fetch user data
const {
  data: user,
  isLoading,
  error,
  refetch,
} = useQuery({
  key: ["me"],
  query: getMe,
});

// Update contact mutation
const { mutate: updateContactMutation, isLoading: isSaving } = useMutation({
  mutation: (variables: { id: string; data: CreateContactData }) =>
    updateContact(variables.id, variables.data),
  onSuccess: () => {
    isEditMode.value = false;
    // Invalidate the user query to refresh the data
    queryCache.invalidateQueries({ key: ["me"] });
  },
});

const authStore = useAuthStore();
const handleUpdateContact = async (data: CreateCompanyRepData) => {
  if (!user.value?.data.contactObject?.id) return;

  // Extract contact data from the form data
  const contactData: CreateContactData = {
    gender: data.contact?.gender,
    language: data.contact?.language,
    phones: data.contact?.phones || [],
    socials: data.contact?.socials || {},
    mails: data.contact?.mails || [],
  };

  updateContactMutation({
    id: user.value.data.contactObject.id,
    data: contactData,
  });

  // Assert
  if (!authStore.member) return;

  authStore.member.contactObject = {
    ...authStore.member?.contactObject,
    ...contactData,
  };
};

const userConnectedEmail = computed(() => {
  return user.value?.data?.sinfoid
    ? `${user.value.data.sinfoid}@sinfo.org`
    : authStore.sinfoEmail;
});

const syncThreads = async (silent = false, fullScan = false) => {
  const eventId = eventStore.selectedEvent?.id;
  if (!eventId) {
    if (!silent) {
      toast.warning({
        title: "No Edition Selected",
        description: "Please select an event edition before syncing threads.",
      });
    }
    return;
  }

  if (!silent) {
    toast.info({
      title: "Syncing Gmail Threads",
      description:
        "Checking recent communications for your assigned companies...",
    });
  }

  try {
    const results = fullScan
      ? await autoLinkEventEntities(eventId, { forceReScan: true })
      : await syncRecentGmailUpdates(eventId);
    const newlyLinked = results.filter((r) => r.status === "SUCCESS").length;
    const alreadyLinked = results.filter(
      (r) => r.status === "ALREADY_LINKED",
    ).length;
    toast.success({
      title: "Sync Complete",
      description:
        newlyLinked > 0
          ? `Linked ${newlyLinked} new thread(s). Total ${alreadyLinked + newlyLinked} thread(s) in sync.`
          : "Email communications are up to date.",
    });

    warnUnlinkedContacted(results);
  } catch (err) {
    console.error("Failed to sync threads:", err);
    toast.error({
      title: "Sync Failed",
      description:
        err instanceof Error ? err.message : "Failed to sync Gmail threads.",
    });
  }
};

const onGoogleConnected = async (userEmail?: string | null) => {
  authStore.connectGoogle();
  toast.success({
    title: "Gmail Connected",
    description: `Connected as ${userEmail || "SINFO member"}. Starting automatic sync...`,
  });
  await syncThreads(true);
};

const connectGoogle = async () => {
  const userEmail = userConnectedEmail.value;

  // If token is already present and unexpired (e.g. from Deck login), connect immediately without popups
  if (authStore.hasValidGoogleToken) {
    await onGoogleConnected(userEmail);
    return;
  }

  // Otherwise request token directly targeting the SINFO account without account picker
  const success = await requestGoogleToken({
    prompt: "",
    hint: userEmail ?? undefined,
  });

  if (success) {
    await onGoogleConnected(userEmail);
  } else {
    toast.error({
      title: "Connection Failed",
      description: "Could not connect to your SINFO Gmail account.",
    });
  }
};

const disconnectGoogle = () => {
  authStore.disconnectGoogle();
  toast.info({
    title: "Gmail Disconnected",
    description: "Your Gmail account has been disconnected.",
  });
};

const handleImageError = (event: Event) => {
  const img = event.target as HTMLImageElement;
  img.src = "/src/assets/noImage.png"; // Fallback image
};

// Utility functions
const formatGender = (gender: Gender): string => {
  switch (gender) {
    case "MALE":
      return "Male";
    case "FEMALE":
      return "Female";
    case "OTHER":
      return "Other";
    default:
      return "";
  }
};

const formatLanguage = (language: Language): string => {
  switch (language) {
    case "PORTUGUESE":
      return "🇵🇹 Portuguese";
    case "ENGLISH":
      return "🇺🇸 English";
    default:
      return "";
  }
};

const hasSocials = (socials?: ContactSocials): boolean => {
  if (!socials) return false;
  return !!(
    socials.linkedin ||
    socials.twitter ||
    socials.facebook ||
    socials.github ||
    socials.skype
  );
};

const linkedinUrl = (username: string): string => {
  if (username.startsWith("http")) return username;
  return `https://linkedin.com/in/${username}`;
};

const twitterUrl = (username: string): string => {
  if (username.startsWith("http")) return username;
  const cleanUsername = username.replace("@", "");
  return `https://twitter.com/${cleanUsername}`;
};

const facebookUrl = (username: string): string => {
  if (username.startsWith("http")) return username;
  return `https://facebook.com/${username}`;
};

const githubUrl = (username: string): string => {
  if (username.startsWith("http")) return username;
  return `https://github.com/${username}`;
};
</script>
