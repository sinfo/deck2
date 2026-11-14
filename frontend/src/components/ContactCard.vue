<template>
  <Card class="relative w-full gap-0 py-2.5">
    <!-- Primary contact crown, sitting on the card's top-left border -->
    <div
      v-if="isPrimary"
      class="absolute -top-2.5 -left-2.5 z-10 bg-orange-100 text-orange-600 rounded-full p-1 border border-orange-200 shadow-sm"
      title="Primary contact (used in bulk emails)"
    >
      <CrownIcon class="size-3" />
    </div>

    <!-- Overlay backdrop when popover is open -->
    <div
      v-if="isEditFormOpen || isDeleteConfirmOpen"
      class="fixed inset-0 bg-black/20 z-40 transition-opacity duration-200"
      @click="closeAllPopovers"
    ></div>

    <CardContent class="px-4">
      <div v-if="!contact" class="text-center text-muted-foreground py-4">
        No contact information available
      </div>

      <div v-else class="space-y-1">
        <!-- Header: name, socials, meta and actions -->
        <div class="flex items-start gap-3">
          <div class="flex-1 min-w-0">
            <!-- Socials wrap to their own line when they don't fit next to the name -->
            <div class="flex flex-wrap items-center gap-x-2 gap-y-0.5">
              <h3
                class="font-semibold text-sm leading-tight truncate min-w-0 max-w-full"
                :title="contactName"
              >
                {{ contactName || "Unnamed Contact" }}
              </h3>
              <div
                v-if="socialLinks.length"
                class="flex items-center gap-0.5 -mx-0.5"
              >
                <a
                  v-for="social in socialLinks"
                  :key="social.label"
                  :href="social.href"
                  :target="social.external ? '_blank' : undefined"
                  rel="noopener noreferrer"
                  :title="social.label"
                  :aria-label="social.label"
                  class="p-0.5 rounded transition-colors hover:bg-accent"
                  :class="social.color"
                >
                  <component :is="social.icon" class="size-3.5" />
                </a>
              </div>
            </div>
            <div
              v-if="contact.gender || contact.language"
              class="mt-0.5 flex items-center gap-1.5 text-xs text-muted-foreground"
            >
              <span v-if="contact.gender">
                {{ formatGender(contact.gender) }}
              </span>
              <span v-if="contact.gender && contact.language">·</span>
              <span
                v-if="contact.language"
                class="text-[10px] font-medium tracking-wide"
                :title="formatLanguageName(contact.language)"
              >
                {{ formatLanguage(contact.language) }}
              </span>
            </div>
          </div>

          <!-- Action buttons -->
          <div v-if="canEdit" class="flex items-center flex-shrink-0 -mr-1">
            <Popover v-model:open="isEditFormOpen">
              <PopoverTrigger as-child>
                <Button
                  variant="ghost"
                  size="icon"
                  class="size-7 text-muted-foreground"
                  :disabled="isSaving"
                  title="Edit contact"
                  aria-label="Edit contact"
                >
                  <PencilIcon class="size-3.5" />
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
                    v-if="contact"
                    :without-name="entityType !== 'company'"
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
              <PopoverTrigger as-child>
                <Button
                  variant="ghost"
                  size="icon"
                  :disabled="isDeleting"
                  class="size-7 text-muted-foreground hover:text-destructive hover:bg-destructive/10"
                  :title="isDeleting ? 'Deleting...' : 'Remove contact'"
                  aria-label="Remove contact"
                >
                  <Loader2Icon
                    v-if="isDeleting"
                    class="size-3.5 animate-spin"
                  />
                  <Trash2Icon v-else class="size-3.5" />
                </Button>
              </PopoverTrigger>
              <PopoverContent class="w-80">
                <ConfirmDelete
                  title="Confirm deletion"
                  message="Are you sure you want to remove this contact? This action cannot be undone."
                  :is-deleting="isDeleting"
                  @cancel="isDeleteConfirmOpen = false"
                  @confirm="confirmDelete"
                />
              </PopoverContent>
            </Popover>
          </div>
        </div>

        <!-- Emails and phones -->
        <div
          v-if="contact.mails.length || contact.phones.length"
          class="space-y-0.5"
        >
          <div
            v-for="mail in contact.mails"
            :key="mail.mail"
            class="flex items-center gap-2 text-sm min-w-0"
          >
            <MailIcon class="size-3.5 flex-shrink-0 text-muted-foreground" />
            <a
              :href="`mailto:${mail.mail}`"
              class="truncate hover:underline"
              :title="mail.mail"
            >
              {{ mail.mail }}
            </a>
            <Badge
              v-if="mail.personal"
              variant="secondary"
              class="text-[10px] px-1.5 py-0 flex-shrink-0"
            >
              Personal
            </Badge>
            <button
              type="button"
              class="flex-shrink-0 p-0.5 rounded text-muted-foreground hover:text-foreground hover:bg-accent transition-colors cursor-pointer"
              :title="copiedEmail === mail.mail ? 'Copied!' : 'Copy email'"
              aria-label="Copy email"
              @click="copyEmail(mail.mail)"
            >
              <CheckIcon
                v-if="copiedEmail === mail.mail"
                class="size-3.5 text-green-600"
              />
              <CopyIcon v-else class="size-3.5" />
            </button>
          </div>
          <div
            v-for="phone in contact.phones"
            :key="phone.phone"
            class="flex items-center gap-2 text-sm min-w-0"
          >
            <PhoneIcon class="size-3.5 flex-shrink-0 text-muted-foreground" />
            <a :href="`tel:${phone.phone}`" class="truncate hover:underline">
              {{ phone.phone }}
            </a>
          </div>
          <div v-if="copyError" class="text-xs text-destructive">
            {{ copyError }}
          </div>
        </div>
      </div>
    </CardContent>
  </Card>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, type Component } from "vue";
import { useMutation, useQueryCache } from "@pinia/colada";
import type { Contact } from "@/dto/contacts";
import type { CreateContactData } from "@/dto/contacts";
import { Gender, Language } from "@/dto/contacts";
import { updateContact } from "@/api/contacts";
import { updateCompanyRepresentative } from "@/api/companies";
import Card from "./ui/card/Card.vue";
import CardContent from "./ui/card/CardContent.vue";
import Badge from "./ui/badge/Badge.vue";
import Button from "./ui/button/Button.vue";
import { Popover, PopoverContent, PopoverTrigger } from "./ui/popover";
import ContactForm from "./companies/ContactForm.vue";
import ConfirmDelete from "@/components/ConfirmDelete.vue";
import type { CreateCompanyRepData } from "@/dto/companies";
import {
  CheckIcon,
  CopyIcon,
  CrownIcon,
  FacebookIcon,
  GithubIcon,
  LinkedinIcon,
  Loader2Icon,
  MailIcon,
  MessageCircleIcon,
  PencilIcon,
  PhoneIcon,
  Trash2Icon,
  TwitterIcon,
} from "lucide-vue-next";

interface Props {
  contact?: Contact;
  contactName?: string;
  canEdit?: boolean;
  canDelete?: boolean;
  entityId?: string;
  entityType?: "company" | "speaker";
  repId?: string;
  isDeleting?: boolean;
  isPrimary?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  canEdit: false,
  canDelete: false,
  isDeleting: false,
  isPrimary: false,
  contact: undefined,
  contactName: undefined,
  entityId: undefined,
  entityType: undefined,
  repId: undefined,
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

const handleUpdateContact = async (data: CreateCompanyRepData) => {
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

  // If this contact is a company representative, also persist the representative's name
  // through the companyRep endpoint so the rep name is updated.
  if (props.entityType === "company" && props.repId) {
    try {
      await updateCompanyRepresentative(props.repId, {
        name: data.name,
        contact: data.contact,
      });

      // Invalidate representatives query for this company so UI refreshes
      if (props.entityId) {
        queryCache.invalidateQueries({
          key: ["company-representatives", props.entityId],
        });
      }
    } catch (err) {
      // Log and continue — contact update already attempted
      console.error("Failed to update company representative:", err);
    }
  }

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

interface SocialLink {
  label: string;
  href: string;
  icon: Component;
  color: string;
  external: boolean;
}

const socialLinks = computed<SocialLink[]>(() => {
  const socials = props.contact?.socials;
  if (!socials) return [];
  const links: SocialLink[] = [];
  if (socials.linkedin)
    links.push({
      label: "LinkedIn",
      href: linkedinUrl(socials.linkedin),
      icon: LinkedinIcon,
      color: "text-[#0A66C2]",
      external: true,
    });
  if (socials.twitter)
    links.push({
      label: "Twitter",
      href: twitterUrl(socials.twitter),
      icon: TwitterIcon,
      color: "text-sky-500",
      external: true,
    });
  if (socials.facebook)
    links.push({
      label: "Facebook",
      href: facebookUrl(socials.facebook),
      icon: FacebookIcon,
      color: "text-[#1877F2]",
      external: true,
    });
  if (socials.github)
    links.push({
      label: "GitHub",
      href: githubUrl(socials.github),
      icon: GithubIcon,
      color: "text-foreground",
      external: true,
    });
  if (socials.skype)
    links.push({
      label: "Skype",
      href: `skype:${socials.skype}?chat`,
      icon: MessageCircleIcon,
      color: "text-cyan-600",
      external: false,
    });
  return links;
});

const formatLanguage = (language: Language): string => {
  switch (language) {
    case Language.PORTUGUESE:
      return "PT";
    case Language.ENGLISH:
      return "EN";
    default:
      return "";
  }
};

const formatLanguageName = (language: Language): string => {
  switch (language) {
    case Language.PORTUGUESE:
      return "Portuguese";
    case Language.ENGLISH:
      return "English";
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

const copiedEmail = ref<string | null>(null);
const copyError = ref<string | null>(null);

const copyEmail = async (email: string) => {
  if (!navigator?.clipboard) {
    copyError.value = "Clipboard not available";
    setTimeout(() => (copyError.value = null), 2000);
    return;
  }

  try {
    await navigator.clipboard.writeText(email);
    copiedEmail.value = email;
    setTimeout(() => (copiedEmail.value = null), 2000);
  } catch (err) {
    copyError.value = "Failed to copy email";
    setTimeout(() => (copyError.value = null), 2000);
    console.error("Failed to copy email:", err);
  }
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
