<template>
  <Card class="w-full">
    <!-- Overlay backdrop when popover is open -->
    <div
      v-if="isEditFormOpen || isDeleteConfirmOpen"
      class="fixed inset-0 bg-black/20 z-40 transition-opacity duration-200"
      @click="closeAllPopovers"
    ></div>

    <CardContent>
      <div v-if="!contact" class="text-center text-muted-foreground py-8">
        No contact information available
      </div>

      <div v-else class="space-y-4">
        <!-- Header with name and buttons -->
        <div class="space-y-3">
          <!-- Name and badges -->
          <div v-if="contactName">
            <h3 class="font-semibold text-base">{{ contactName }}</h3>
            <div
              v-if="contact.gender || contact.language"
              class="mt-1 flex gap-2"
            >
              <Badge v-if="contact.gender" variant="secondary" class="text-xs">
                {{ formatGender(contact.gender) }}
              </Badge>
              <Badge v-if="contact.language" variant="outline" class="text-xs">
                {{ formatLanguage(contact.language) }}
              </Badge>
            </div>
          </div>

          <!-- Action buttons -->
          <div class="flex gap-2" v-if="canEdit">
            <Popover v-model:open="isEditFormOpen">
              <PopoverTrigger asChild>
                <Button variant="outline" size="sm" :disabled="isSaving">
                  Edit
                </Button>
              </PopoverTrigger>
              <PopoverContent
                :side="popoverSide"
                :side-offset="8"
                :collision-padding="20"
                :avoid-collisions="true"
                :sticky="'partial'"
                class="w-[420px] max-w-[calc(100vw-40px)] max-h-[85vh] overflow-hidden flex flex-col z-50"
              >
                <div class="p-6 pb-4 border-b flex-shrink-0">
                  <h3 class="font-semibold text-lg">
                    {{ contactName || "Unnamed Contact" }}
                  </h3>
                </div>
                <div class="flex-1 overflow-y-auto p-6 min-h-0">
                  <ContactForm
                    without-name
                    v-if="contact"
                    mode="edit"
                    :initial-data="{
                      id: contact.id,
                      name: contactName || '',
                      contact: contact,
                    }"
                    :is-loading="isSaving"
                    @submit="handleUpdateContact"
                    @cancel="isEditFormOpen = false"
                  />
                </div>
              </PopoverContent>
            </Popover>

            <Popover v-if="canDelete" v-model:open="isDeleteConfirmOpen">
              <PopoverTrigger asChild>
                <Button
                  variant="outline"
                  size="sm"
                  :disabled="isDeleting"
                  class="text-destructive hover:text-destructive"
                >
                  {{ isDeleting ? "Deleting..." : "Remove" }}
                </Button>
              </PopoverTrigger>
              <PopoverContent class="w-80">
                <div class="space-y-3">
                  <div>
                    <h4 class="font-medium text-sm">Confirm deletion</h4>
                    <p class="text-sm text-muted-foreground mt-1">
                      Are you sure you want to remove this contact? This action
                      cannot be undone.
                    </p>
                  </div>
                  <div class="flex justify-end gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      @click="isDeleteConfirmOpen = false"
                    >
                      Cancel
                    </Button>
                    <Button
                      variant="destructive"
                      size="sm"
                      :disabled="isDeleting"
                      @click="confirmDelete"
                    >
                      {{ isDeleting ? "Deleting..." : "Delete" }}
                    </Button>
                  </div>
                </div>
              </PopoverContent>
            </Popover>
          </div>
        </div>

        <div v-if="contact.mails.length" class="space-y-2">
          <h4 class="text-sm font-medium text-muted-foreground">Email</h4>
          <div class="space-y-1">
            <div v-for="mail in contact.mails" :key="mail.mail" class="text-sm">
              <div class="flex items-start gap-2">
                <div class="flex-1 min-w-0">
                  <div class="flex flex-wrap items-center gap-2">
                    <a
                      :href="`mailto:${mail.mail}`"
                      class="text-primary hover:underline min-w-0 flex-shrink-0"
                    >
                      {{ mail.mail }}
                    </a>
                    <div
                      v-if="mail.personal || !mail.valid"
                      class="flex gap-1 flex-shrink-0"
                    >
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
            </div>
          </div>
        </div>

        <div v-if="contact.phones.length" class="space-y-2">
          <h4 class="text-sm font-medium text-muted-foreground">Phone</h4>
          <div class="space-y-1">
            <div
              v-for="phone in contact.phones"
              :key="phone.phone"
              class="text-sm"
            >
              <div class="flex items-start gap-2">
                <div class="flex-1 min-w-0">
                  <div class="flex flex-wrap items-center gap-2">
                    <a
                      :href="`tel:${phone.phone}`"
                      class="text-primary hover:underline min-w-0 flex-shrink-0"
                    >
                      {{ phone.phone }}
                    </a>
                    <div v-if="!phone.valid" class="flex gap-1 flex-shrink-0">
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
              </div>
            </div>
          </div>
        </div>

        <div v-if="hasSocials(contact.socials)" class="space-y-2">
          <h4 class="text-sm font-medium text-muted-foreground">
            Social Media
          </h4>
          <div class="flex flex-wrap gap-2">
            <a
              v-if="contact.socials.linkedin"
              :href="linkedinUrl(contact.socials.linkedin)"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1 text-xs px-2 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition-colors"
            >
              LinkedIn
            </a>
            <a
              v-if="contact.socials.twitter"
              :href="twitterUrl(contact.socials.twitter)"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1 text-xs px-2 py-1 bg-sky-100 text-sky-700 rounded hover:bg-sky-200 transition-colors"
            >
              Twitter
            </a>
            <a
              v-if="contact.socials.facebook"
              :href="facebookUrl(contact.socials.facebook)"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1 text-xs px-2 py-1 bg-blue-100 text-blue-800 rounded hover:bg-blue-200 transition-colors"
            >
              Facebook
            </a>
            <a
              v-if="contact.socials.github"
              :href="githubUrl(contact.socials.github)"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1 text-xs px-2 py-1 bg-gray-100 text-gray-700 rounded hover:bg-gray-200 transition-colors"
            >
              GitHub
            </a>
            <a
              v-if="contact.socials.skype"
              :href="`skype:${contact.socials.skype}?chat`"
              class="inline-flex items-center gap-1 text-xs px-2 py-1 bg-cyan-100 text-cyan-700 rounded hover:bg-cyan-200 transition-colors"
            >
              Skype
            </a>
          </div>
        </div>
      </div>
    </CardContent>
  </Card>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from "vue";
import { useMutation, useQueryCache } from "@pinia/colada";
import type { Contact } from "@/dto/contacts";
import type { ContactSocials, CreateContactData } from "@/dto/contacts";
import { Gender, Language } from "@/dto/contacts";
import { updateContact } from "@/api/contacts";
import Card from "./ui/card/Card.vue";
import CardContent from "./ui/card/CardContent.vue";
import Badge from "./ui/badge/Badge.vue";
import Button from "./ui/button/Button.vue";
import { Popover, PopoverContent, PopoverTrigger } from "./ui/popover";
import ContactForm from "./companies/ContactForm.vue";

interface Props {
  contact?: Contact;
  contactName?: string;
  canEdit?: boolean;
  canDelete?: boolean;
  entityId?: string;
  entityType?: "company" | "speaker";
  isDeleting?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  canEdit: false,
  canDelete: false,
  isDeleting: false,
});

const emit = defineEmits<{
  updated: [];
  delete: [];
}>();

// Responsive positioning
const windowWidth = ref(0);

const updateWindowWidth = () => {
  windowWidth.value = window.innerWidth;
};

onMounted(() => {
  updateWindowWidth();
  window.addEventListener("resize", updateWindowWidth);
});

onUnmounted(() => {
  window.removeEventListener("resize", updateWindowWidth);
});

const popoverSide = computed(() => {
  return windowWidth.value < 768 ? "bottom" : "right";
});

const isEditFormOpen = ref(false);
const isDeleteConfirmOpen = ref(false);
const queryCache = useQueryCache();

const { mutate: updateContactMutation, isLoading: isSaving } = useMutation({
  mutation: (variables: { id: string; data: CreateContactData }) =>
    updateContact(variables.id, variables.data),
  onSuccess: () => {
    isEditFormOpen.value = false;
    emit("updated");
    // Invalidate relevant queries
    if (props.entityId && props.entityType) {
      queryCache.invalidateQueries({ key: [props.entityType, props.entityId] });
    }
  },
});

const handleUpdateContact = async (data: any) => {
  if (!props.contact?.id) return;

  // Extract contact data from the form data
  const contactData: CreateContactData = {
    gender: data.contact?.gender,
    language: data.contact?.language,
    phones: data.contact?.phones || [],
    socials: data.contact?.socials || {},
    mails: data.contact?.mails || [],
  };

  updateContactMutation({ id: props.contact.id, data: contactData });
  isEditFormOpen.value = false;
};

const formatGender = (gender: Gender): string => {
  switch (gender) {
    case Gender.MALE:
      return "Male";
    case Gender.FEMALE:
      return "Female";
    case Gender.OTHER:
      return "Other";
    default:
      return "";
  }
};

const formatLanguage = (language: Language): string => {
  switch (language) {
    case Language.PORTUGUESE:
      return "🇵🇹";
    case Language.ENGLISH:
      return "🇺🇸";
    default:
      return "";
  }
};

const confirmDelete = () => {
  isDeleteConfirmOpen.value = false;
  emit("delete");
};

const closeAllPopovers = () => {
  isEditFormOpen.value = false;
  isDeleteConfirmOpen.value = false;
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
