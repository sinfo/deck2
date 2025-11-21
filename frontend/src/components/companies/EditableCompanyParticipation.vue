<template>
  <Card class="p-4">
    <div class="space-y-4">
      <div class="flex items-center justify-between">
        <h4 class="font-medium">{{ getEventName(participation.event) }}</h4>

        <div class="flex items-center gap-2">
          <Popover
            :open="isStatusMenuOpen"
            @update:open="isStatusMenuOpen = $event"
          >
            <PopoverTrigger as-child>
              <Badge
                :class="participationStatusColor[selectedStatus]?.background"
                class="text-xs flex items-center gap-1 cursor-pointer"
              >
                {{ humanReadableParticipationStatus[selectedStatus] }}
                <ChevronDown class="w-3 h-3" />
              </Badge>
            </PopoverTrigger>
            <PopoverContent class="w-56 p-0">
              <div class="flex flex-col">
                <button
                  v-for="(label, value) in humanReadableParticipationStatus"
                  :key="value"
                  :class="[
                    'px-3 py-2 text-sm text-left hover:bg-accent cursor-pointer',
                    selectedStatus === value && 'bg-accent',
                  ]"
                  @click="selectStatus(value as ParticipationStatus)"
                >
                  {{ label }}
                </button>
              </div>
            </PopoverContent>
          </Popover>

          <Button
            v-if="!isEditing"
            variant="outline"
            size="sm"
            @click="startEditing"
          >
            Edit
          </Button>

          <div v-else class="flex gap-2">
            <Button
              size="sm"
              :disabled="isSaving || isStatusUpdating"
              @click="saveChanges"
            >
              {{
                isSaving
                  ? "Saving..."
                  : isStatusUpdating
                    ? "Updating..."
                    : "Save"
              }}
            </Button>
            <Button variant="outline" size="sm" @click="cancelEditing"
              >Cancel</Button
            >
          </div>
        </div>
      </div>

      <div v-if="!isEditing" class="space-y-3">
        <!-- Read-only view -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 items-start">
          <div class="flex items-center gap-2">
            <Image
              :src="getMember(participation.member)?.img"
              :alt="getMember(participation.member)?.name"
              class="w-8 h-8 rounded-full object-cover border"
            />
            <div>
              <div class="text-sm font-medium">
                {{ getMember(participation.member)?.name }}
              </div>
              <div class="text-xs text-muted-foreground">Responsible</div>
            </div>
          </div>

          <div v-if="participation.confirmed" class="text-sm">
            <span class="font-medium">Confirmed:</span>
            <div class="mt-1 text-muted-foreground flex items-center gap-4">
              <span>{{ formatDate(participation.confirmed) }}</span>
              <span
                v-if="participation.package && packageName"
                class="text-xs text-muted-foreground"
                >· {{ packageName }}</span
              >
            </div>
          </div>

          <div v-if="participation.notes" class="text-sm">
            <span class="font-medium">Notes:</span>
            <div class="mt-1 text-muted-foreground">
              {{ participation.notes }}
            </div>
          </div>
        </div>

        <div v-if="participation.partner" class="flex items-center gap-1">
          <Badge variant="secondary" class="text-xs">Partner</Badge>
        </div>
      </div>

      <div v-else class="space-y-4">
        <!-- Editable form -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
          <div class="space-y-2">
            <MemberSelect
              v-model="editForm.member"
              label="Responsible Member"
              placeholder="Select a member..."
              :event-id="participation.event"
            />
          </div>

          <div class="space-y-2">
            <Label for="confirmed-date">Confirmed Date</Label>
            <input
              id="confirmed-date"
              v-model="editForm.confirmed"
              type="datetime-local"
              class="w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>

          <div class="space-y-2">
            <Label for="notes">Notes</Label>
            <textarea
              id="notes"
              v-model="editForm.notes"
              rows="3"
              class="w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-vertical"
              placeholder="Add notes..."
            />
          </div>
        </div>

        <div class="grid grid-cols-1 gap-4">
          <div class="space-y-2">
            <Label for="package-select">Package</Label>
            <div>
              <Select v-model="selectedPackageId">
                <SelectTrigger>
                  <SelectValue placeholder="-- Select package --" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem
                    v-for="opt in packageOptions"
                    :key="opt.id"
                    :value="opt.id"
                  >
                    {{ opt.name }}
                  </SelectItem>
                </SelectContent>
              </Select>
              <div
                v-if="isPackageLoading"
                class="text-xs text-muted-foreground mt-1"
              >
                Loading packages...
              </div>
              <div
                v-if="isPackageUpdating"
                class="text-xs text-muted-foreground mt-1"
              >
                Updating package...
              </div>
              <div
                v-if="!isPackageLoading && packageOptions.length === 0"
                class="text-xs text-muted-foreground mt-1"
              >
                No packages available for this event.
              </div>
            </div>
          </div>
        </div>

        <div class="flex items-center space-x-2">
          <input
            id="partner-checkbox"
            v-model="editForm.partner"
            type="checkbox"
            class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
          />
          <Label for="partner-checkbox" class="text-sm">
            Partner Company
          </Label>
        </div>
      </div>
    </div>
  </Card>
</template>

<script setup lang="ts">
import { ref, reactive, watch } from "vue";
import useToast from "@/lib/toast";
import { useQuery } from "@pinia/colada";
import { getAllEvents } from "@/api/events";
import { getAllMembers } from "@/api/members";
import {
  useCompanyParticipationMutation,
  useCompanyParticipationStatusMutation,
} from "@/mutations/companies";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import MemberSelect from "@/components/members/MemberSelect.vue";
import { useCompanyParticipationPackageMutation } from "@/mutations/companies";
import { getPackageById } from "@/api/packages";
import type { Package } from "@/dto/packages";
import type {
  CompanyParticipation,
  UpdateCompanyParticipationData,
} from "@/dto/companies";
import {
  humanReadableParticipationStatus,
  type ParticipationStatus,
  participationStatusColor,
} from "@/dto";
import { ChevronDown } from "lucide-vue-next";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import Image from "../Image.vue";

interface Props {
  participation: CompanyParticipation;
  companyId: string;
}

const props = defineProps<Props>();

const isEditing = ref(false);
const isSaving = ref(false);
const isStatusMenuOpen = ref(false);
const isStatusUpdating = ref(false);
const selectedStatus = ref<ParticipationStatus>(props.participation.status);

const updateMutation = useCompanyParticipationMutation();
const statusMutation = useCompanyParticipationStatusMutation();
statusMutation.companyId.value = props.companyId;

const formatToISOString = (date: Date): string => {
  return date.toISOString();
};

const formatToDatetimeLocal = (isoString: string | null): string => {
  if (!isoString) return "";
  try {
    const date = new Date(isoString);
    // Format for datetime-local input (YYYY-MM-DDTHH:mm)
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    const hours = String(date.getHours()).padStart(2, "0");
    const minutes = String(date.getMinutes()).padStart(2, "0");
    return `${year}-${month}-${day}T${hours}:${minutes}`;
  } catch {
    return "";
  }
};

const convertDatetimeLocalToISO = (datetimeLocal: string): string | null => {
  if (!datetimeLocal || datetimeLocal.trim() === "") return null;
  try {
    // Add seconds if not present and convert to ISO 8601
    const date = new Date(
      datetimeLocal.includes(":") && datetimeLocal.split(":").length === 2
        ? `${datetimeLocal}:00`
        : datetimeLocal,
    );
    return date.toISOString();
  } catch {
    return null;
  }
};

const editForm = reactive<UpdateCompanyParticipationData>({
  member: props.participation.member,
  partner: props.participation.partner,
  confirmed: formatToDatetimeLocal(
    props.participation.confirmed || formatToISOString(new Date()),
  ),
  notes: props.participation.notes,
});

const packageOptions = ref<{ id: string; name: string }[]>([]);
const selectedPackageId = ref<string>(
  props.participation.package ? String(props.participation.package) : "",
);
const packageName = ref<string | null>(null);
const isPackageLoading = ref(false);
const isPackageUpdating = ref(false);
const packageMutation = useCompanyParticipationPackageMutation();
packageMutation.companyId.value = props.companyId;

const { toast } = useToast();

const { data: eventsData } = useQuery({
  key: () => ["events"],
  query: () => getAllEvents(),
});

const { data: membersData } = useQuery({
  key: () => ["members"],
  query: () => getAllMembers(),
});

const selectStatus = async (status: ParticipationStatus) => {
  const previous = selectedStatus.value;
  selectedStatus.value = status;
  isStatusMenuOpen.value = false;
  try {
    isStatusUpdating.value = true;
    statusMutation.companyId.value = props.companyId;
    await statusMutation.mutate(status);
  } catch (err) {
    console.error("Failed to update participation status:", err);
    // revert value on error
    selectedStatus.value = previous;
  } finally {
    isStatusUpdating.value = false;
  }
};

const startEditing = () => {
  // entering edit mode for participation
  isEditing.value = true;
  selectedStatus.value = props.participation.status;
  editForm.member = props.participation.member;
  editForm.partner = props.participation.partner;
  // If no confirmed date exists, set it to current time, otherwise convert existing date
  const confirmedDate = props.participation.confirmed;
  editForm.confirmed = formatToDatetimeLocal(confirmedDate);
  editForm.notes = props.participation.notes;

  // Load event packages for selection (no-op if events not yet loaded)
  loadEventPackages(props.participation.event);
};

const loadEventPackages = async (eventId: number) => {
  packageOptions.value = [];
  const ev = eventsData.value?.data?.find((e) => e.id === eventId);

  if (!ev) return;

  isPackageLoading.value = true;
  try {
    const all = await (await import("@/api/packages")).getPackages();
    const allPkgs = all as Package[];
    const name = String(ev.name || "");
    const pkgs =
      eventId != null
        ? allPkgs.filter((ap) => String(ap.name || "").startsWith(name))
        : [];

    packageOptions.value = pkgs.map((p) => ({
      id: String(p.id),
      name: p.name || "(no name)",
    }));
  } catch (err) {
    console.error("Failed to load packages for event:", err);
    packageOptions.value = [];
  } finally {
    isPackageLoading.value = false;
  }
};

const loadPackageName = async (pkgId: string | null) => {
  packageName.value = null;
  if (!pkgId) return;
  try {
    const pkg = await getPackageById(pkgId);
    packageName.value = pkg?.name || null;
  } catch (err) {
    console.error("Failed to load package name:", err);
    packageName.value = null;
  }
};

loadPackageName(
  props.participation.package ? String(props.participation.package) : null,
);

watch(
  () => props.participation.package,
  (newVal) => {
    loadPackageName(newVal ? String(newVal) : null);
  },
);

watch(
  () => eventsData.value?.data,
  (newVal) => {
    if (isEditing.value && newVal) {
      loadEventPackages(props.participation.event);
    }
  },
);

const onPackageChange = async () => {
  if (!selectedPackageId.value) return;
  const previous = props.participation.package
    ? String(props.participation.package)
    : "";
  try {
    isPackageUpdating.value = true;
    packageMutation.packageId.value = selectedPackageId.value;
    await packageMutation.mutate();
    await loadPackageName(selectedPackageId.value);
  } catch (err) {
    console.error("Failed to update participation package:", err);
    selectedPackageId.value = previous;
    await loadPackageName(previous || null);
    toast.error({
      title: "Failed to update package",
      description:
        "Could not update the participation package. Your selection was reverted.",
    });
  } finally {
    isPackageUpdating.value = false;
  }
};

// Watch for select changes (fires when user picks a package from the Select)
watch(selectedPackageId, (newVal, oldVal) => {
  if (newVal === oldVal) return;
  onPackageChange();
});

const cancelEditing = () => {
  isEditing.value = false;
};

const saveChanges = async () => {
  isSaving.value = true;

  try {
    const dataToSend = {
      ...editForm,
      confirmed: convertDatetimeLocalToISO(editForm.confirmed!),
    };

    updateMutation.companyId.value = props.companyId;
    updateMutation.data.value = dataToSend;
    updateMutation.mutate();

    isEditing.value = false;
  } catch (error) {
    console.error("Failed to update company participation:", error);
  } finally {
    isSaving.value = false;
  }
};

const getEventName = (eventId: number) => {
  if (!eventsData.value?.data) return `Event ${eventId}`;
  const event = eventsData.value.data.find((e) => e.id === eventId);
  return event?.name || `Event ${eventId}`;
};

const getMember = (memberId: string) => {
  if (!membersData.value?.data) return null;
  return membersData.value.data.find((m) => m.id === memberId) || null;
};

const formatDate = (dateString: string) => {
  if (!dateString) return "";
  try {
    return new Date(dateString).toLocaleString();
  } catch {
    return dateString;
  }
};
</script>
