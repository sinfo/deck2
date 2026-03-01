<template>
  <TaskTimelineItem
    :step-number="1"
    title="Confirmation"
    :is-complete="isComplete"
  >
    <template #icon>
      <CalendarCheck class="w-4 h-4" />
    </template>
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <!-- Package Selection (companies only) -->
      <div v-if="entityType === 'company'" class="space-y-2">
        <Label for="package-select">Package</Label>
        <Select
          v-model="selectedPackageId"
          :disabled="isPackageUpdating"
          @update:model-value="onPackageChange"
        >
          <SelectTrigger :loading="isPackageUpdating">
            <SelectValue placeholder="Select a package" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem
              v-for="pkg in packageOptions"
              :key="pkg.id"
              :value="pkg.id"
            >
              {{ pkg.name }}
            </SelectItem>
          </SelectContent>
        </Select>
      </div>

      <!-- Confirmation Date (companies only) -->
      <div v-if="entityType === 'company'" class="space-y-2">
        <Label for="confirmed-date">Confirmation Date</Label>
        <DatePicker
          v-model="confirmedDate"
          :loading="isDateUpdating"
          placeholder="Pick a date"
          show-time
          @update:model-value="onConfirmedDateChange"
        />
      </div>
    </div>

    <!-- Speaker-only fields -->
    <template v-if="entityType === 'speaker'">
      <!-- Phone & LinkedIn editable, saved to contact -->
      <div class="mt-4 space-y-2">
        <span class="text-sm font-medium">Contact Details</span>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
          <div class="space-y-1">
            <Label for="speaker-phone" class="text-xs">Phone</Label>
            <Input
              id="speaker-phone"
              v-model="speakerPhone"
              placeholder="+351 900 000 000"
              @blur="saveContact"
            />
          </div>
          <div class="space-y-1">
            <Label for="speaker-linkedin" class="text-xs">LinkedIn</Label>
            <Input
              id="speaker-linkedin"
              v-model="speakerLinkedin"
              placeholder="username or profile URL"
              @blur="saveContact"
            />
          </div>
        </div>
        <p v-if="isSavingContact" class="text-xs text-muted-foreground">
          Saving…
        </p>
      </div>

      <div class="space-y-1 mt-4">
        <Label class="text-sm font-medium"
          >Wants to be tagged on LinkedIn</Label
        >
        <Select v-model="wantsLinkedinTag">
          <SelectTrigger class="w-[200px]">
            <SelectValue placeholder="Select…" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="not_responded">Didn't respond</SelectItem>
            <SelectItem value="yes">Yes</SelectItem>
            <SelectItem value="no">No</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div class="space-y-2 mt-4">
        <Label for="speaker-observations">Observations</Label>
        <Textarea
          id="speaker-observations"
          v-model="speakerObservations"
          placeholder="Any observations about the speaker"
          :rows="3"
        />
      </div>
    </template>
  </TaskTimelineItem>
</template>

<script setup lang="ts">
import { ref, computed, watch } from "vue";
import { useQuery } from "@pinia/colada";
import { getAllEvents } from "@/api/events";
import { getItemById } from "@/api/items";
import type { Item } from "@/dto/item";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { DatePicker } from "@/components/ui/date-picker";
import { Textarea } from "@/components/ui/textarea";
import type { CompanyParticipation } from "@/dto/companies";
import type { SpeakerParticipation } from "@/dto/speakers";
import type { Contact } from "@/dto/contacts";
import type {
  EntityType,
  CompanyTasks,
  SpeakerTasks,
  CompanyTaskConfirmation,
  SpeakerTaskConfirmation,
} from "@/dto/tasks";
import type { Package } from "@/dto/packages";
import {
  useCompanyParticipationPackageMutation,
  useCompanyParticipationMutation,
} from "@/mutations/companies";
import { usePackagesQuery } from "@/mutations/packages";
import { updateContact } from "@/api/contacts";
import useToast from "@/lib/toast";
import TaskTimelineItem from "./TaskTimelineItem.vue";
import { CalendarCheck } from "lucide-vue-next";

interface Props {
  entityId: string;
  entityType: EntityType;
  participation?: CompanyParticipation | SpeakerParticipation;
  contact?: Contact;
  companyTasks?: CompanyTasks;
  speakerTasks?: SpeakerTasks;
}

const props = defineProps<Props>();

const emit = defineEmits<{
  packageChanged: [packageName: string, packageItems: Item[]];
  "update:companyConfirmation": [value: CompanyTaskConfirmation];
  "update:speakerConfirmation": [value: SpeakerTaskConfirmation];
}>();

const { toast } = useToast();

// Helper to check if participation is company type
const isCompanyParticipation = (
  p?: CompanyParticipation | SpeakerParticipation,
): p is CompanyParticipation => {
  return !!p && "confirmed" in p;
};

// Package data (only used for companies)
const { data: packagesData } = usePackagesQuery();
const { data: eventsData } = useQuery({
  key: () => ["events"],
  query: () => getAllEvents(),
});

const packageOptions = computed(() => {
  if (props.entityType !== "company") return [];
  const allPkgs = (packagesData.value || []) as Package[];
  const eventId = props.participation?.event;
  if (!eventId) return [];

  const ev = eventsData.value?.data?.find((e) => e.id === eventId);
  if (!ev) return allPkgs.map((p) => ({ id: String(p.id), name: p.name }));

  const name = String(ev.name || "");
  const pkgs = allPkgs.filter((ap) => String(ap.name || "").startsWith(name));

  return pkgs.map((p) => ({ id: String(p.id), name: p.name }));
});

// Package mutation (companies only)
const packageMutation = useCompanyParticipationPackageMutation();
packageMutation.companyId.value = props.entityId;

const selectedPackageId = ref<string>(
  isCompanyParticipation(props.participation) && props.participation?.package
    ? String(props.participation.package)
    : "",
);
const isPackageUpdating = ref(false);

// Get package name from the packages data
const currentPackageName = computed(() => {
  if (props.entityType !== "company") return "";
  if (!selectedPackageId.value || !packagesData.value) return "";
  const pkg = (packagesData.value as Package[]).find(
    (p) => String(p.id) === selectedPackageId.value,
  );
  return pkg?.name?.toLowerCase() || "";
});

// Get current package items
const currentPackage = computed(() => {
  if (props.entityType !== "company") return null;
  if (!selectedPackageId.value || !packagesData.value) return null;
  return (
    (packagesData.value as Package[]).find(
      (p) => String(p.id) === selectedPackageId.value,
    ) || null
  );
});

// Fetch full item details for the current package
const packageItemsWithDetails = ref<Item[]>([]);

const fetchPackageItems = async () => {
  const pkg = currentPackage.value;
  if (!pkg || !pkg.items || pkg.items.length === 0) {
    packageItemsWithDetails.value = [];
    return;
  }

  try {
    const itemPromises = pkg.items.map((pi) => getItemById(String(pi.item)));
    packageItemsWithDetails.value = await Promise.all(itemPromises);
  } catch (err) {
    console.error("Failed to fetch package items:", err);
    packageItemsWithDetails.value = [];
  }
};

// Watch for package changes and fetch items
watch(
  currentPackage,
  () => {
    fetchPackageItems();
  },
  { immediate: true },
);

// Emit package name and items changes
watch(
  [currentPackageName, packageItemsWithDetails],
  ([newName, newItems]) => {
    emit("packageChanged", newName, newItems);
  },
  { immediate: true },
);

// Confirmation date
const parseIsoToDate = (isoString: string | null): Date | null => {
  if (!isoString) return null;
  try {
    return new Date(isoString);
  } catch {
    return null;
  }
};

const confirmedDate = ref<Date | null>(
  isCompanyParticipation(props.participation)
    ? parseIsoToDate(props.participation?.confirmed || null)
    : null,
);
const isDateUpdating = ref(false);

// Participation mutation for updating confirmed date (companies only)
const companyParticipationMutation = useCompanyParticipationMutation();
companyParticipationMutation.companyId.value = props.entityId;

const onConfirmedDateChange = async (newValue: Date | null) => {
  if (!newValue) return;
  try {
    isDateUpdating.value = true;
    const isoDate = newValue.toISOString();
    companyParticipationMutation.data.value = {
      ...props.participation,
      confirmed: isoDate,
    };
    await companyParticipationMutation.mutateAsync();
    toast.success({ title: "Confirmation date updated" });
  } catch (err) {
    console.error("Failed to update confirmation date:", err);
    toast.error({ title: "Failed to update confirmation date" });
  } finally {
    isDateUpdating.value = false;
  }
};

const onPackageChange = async (newValue: unknown) => {
  const v = newValue == null ? "" : String(newValue);
  if (!v) return;
  try {
    isPackageUpdating.value = true;
    packageMutation.packageId.value = v;
    await packageMutation.mutateAsync();
    toast.success({ title: "Package updated" });
  } catch (err) {
    console.error("Failed to update package:", err);
    toast.error({ title: "Failed to update package" });
  } finally {
    isPackageUpdating.value = false;
  }
};

// Watch for participation changes to sync local state from props
watch(
  () =>
    isCompanyParticipation(props.participation)
      ? props.participation?.package
      : undefined,
  (newVal) => {
    selectedPackageId.value = newVal ? String(newVal) : "";
  },
);

watch(
  () =>
    isCompanyParticipation(props.participation)
      ? props.participation?.confirmed
      : undefined,
  (newVal) => {
    confirmedDate.value = parseIsoToDate(newVal || null);
  },
);

// Completion state
const isComplete = computed(() => {
  if (props.entityType === "company") {
    return !!selectedPackageId.value && !!confirmedDate.value;
  }
  // For speakers, no date needed
  return true;
});

// Speaker-only fields
const speakerObservations = ref<string>(
  props.speakerTasks?.confirmation?.observations ?? "",
);
const wantsLinkedinTag = ref<string>(
  props.speakerTasks?.confirmation?.wantsLinkedinTag ?? "not_responded",
);

// Speaker contact detail shortcuts — editable, saved back to contact
const speakerPhone = ref<string>(props.contact?.phones?.[0]?.phone ?? "");
const speakerLinkedin = ref<string>(props.contact?.socials?.linkedin ?? "");
const isSavingContact = ref(false);

// Sync if contact prop changes externally
watch(
  () => props.contact,
  (c) => {
    speakerPhone.value = c?.phones?.[0]?.phone ?? "";
    speakerLinkedin.value = c?.socials?.linkedin ?? "";
  },
);

const saveContact = async () => {
  if (!props.contact?.id) return;
  // Only save if something actually changed
  const origPhone = props.contact?.phones?.[0]?.phone ?? "";
  const origLinkedin = props.contact?.socials?.linkedin ?? "";
  if (
    speakerPhone.value === origPhone &&
    speakerLinkedin.value === origLinkedin
  )
    return;

  isSavingContact.value = true;
  try {
    // Build updated contact data, preserving all other fields
    const phones = speakerPhone.value.trim()
      ? [{ phone: speakerPhone.value.trim() }]
      : (props.contact.phones ?? []);
    await updateContact(String(props.contact.id), {
      gender: props.contact.gender,
      language: props.contact.language,
      mails: props.contact.mails ?? [],
      phones,
      socials: {
        ...props.contact.socials,
        linkedin: speakerLinkedin.value.trim() || undefined,
      },
    });
    toast.success({ title: "Contact details saved" });
  } catch (err) {
    console.error("Failed to save contact:", err);
    toast.error({ title: "Failed to save contact details" });
  } finally {
    isSavingContact.value = false;
  }
};

// Emit speaker confirmation changes
watch([wantsLinkedinTag, speakerObservations], () => {
  if (props.entityType === "speaker") {
    emit("update:speakerConfirmation", {
      phone: speakerPhone.value,
      linkedin: speakerLinkedin.value,
      wantsLinkedinTag: wantsLinkedinTag.value,
      observations: speakerObservations.value,
    });
  }
});

defineExpose({
  isComplete,
  currentPackageName,
});
</script>
