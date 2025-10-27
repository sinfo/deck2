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
                  <div v-if="user.data.contactObject.gender" class="space-y-1">
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
                        <Badge
                          v-if="!mail.valid"
                          variant="destructive"
                          class="text-xs"
                        >
                          Invalid
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
                      <Badge
                        v-if="!phone.valid"
                        variant="destructive"
                        class="text-xs"
                      >
                        Invalid
                      </Badge>
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
                        linkedinUrl(user.data.contactObject.socials.linkedin)
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
                        facebookUrl(user.data.contactObject.socials.facebook)
                      "
                      target="_blank"
                      rel="noopener noreferrer"
                      class="inline-flex items-center gap-1 text-xs px-2 py-1 bg-blue-100 text-blue-800 rounded hover:bg-blue-200 transition-colors"
                    >
                      Facebook
                    </a>
                    <a
                      v-if="user.data.contactObject.socials.github"
                      :href="githubUrl(user.data.contactObject.socials.github)"
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
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
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

const isEditMode = ref(false);
const queryCache = useQueryCache();

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
