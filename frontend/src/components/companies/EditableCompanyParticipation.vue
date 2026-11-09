<template>
  <Card class="p-4">
    <div class="space-y-4">
      <div class="flex items-center justify-between">
        <h4 class="font-medium">{{ getEventName(participation.event) }}</h4>

        <div class="flex items-center gap-2">
          <ParticipationStatusBadge
            :status="participation.status"
            :entity-id="companyId"
            entity-type="company"
          />

          <Button
            v-if="!isEditing"
            variant="outline"
            size="sm"
            @click="startEditing"
          >
            Edit
          </Button>

          <div v-else class="flex gap-2">
            <Button size="sm" :disabled="isSaving" @click="saveChanges">
              {{ isSaving ? "Saving..." : "Save" }}
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
            <div class="mt-1 text-muted-foreground">
              <span>{{ formatDate(participation.confirmed) }}</span>
            </div>
          </div>

          <div v-if="participation.notes" class="text-sm">
            <span class="font-medium">Notes:</span>
            <div class="mt-1 text-muted-foreground wrap-anywhere">
              {{ participation.notes }}
            </div>
          </div>
        </div>

        <div
          v-if="participation.partner || packageName"
          class="flex items-center gap-1"
        >
          <Badge
            v-if="participation.partner"
            variant="secondary"
            class="text-xs"
            >Partner</Badge
          >
          <Badge v-if="packageName" variant="outline" class="text-xs">{{
            packageName
          }}</Badge>
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
              class="w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:opacity-50 disabled:bg-gray-100 disabled:cursor-not-allowed"
              :disabled="!canEditConfirmedDate"
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
              <Select v-model="selectedPackageId" :disabled="isSaving">
                <SelectTrigger>
                  <SelectValue placeholder="Select package" />
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
import { ref, reactive, watch, computed } from "vue";
import useToast from "@/lib/toast";
import { useQuery } from "@pinia/colada";
import { getAllEvents } from "@/api/events";
import { getAllMembers } from "@/api/members";
import { useCompanyParticipationMutation } from "@/mutations/companies";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import MemberSelect from "@/components/members/MemberSelect.vue";
import { useCompanyParticipationPackageMutation } from "@/mutations/companies";
import { usePackagesQuery, usePackageQuery } from "@/mutations/packages";
import { usePermissions } from "@/composables/usePermissions";
import type { Package } from "@/dto/packages";
import type {
  CompanyParticipation,
  UpdateCompanyParticipationData,
} from "@/dto/companies";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import Image from "../Image.vue";
import ParticipationStatusBadge from "@/components/ParticipationStatusBadge.vue";

interface Props {
  participation: CompanyParticipation;
  companyId: string;
}

const props = defineProps<Props>();

const { isCoordinatorOrAdmin } = usePermissions();
const canEditConfirmedDate = computed(() => {
  return isCoordinatorOrAdmin.value === true;
});

const isEditing = ref(false);
const isSaving = ref(false);

const updateMutation = useCompanyParticipationMutation();

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

const selectedPackageId = ref<string>(
  props.participation.package ? String(props.participation.package) : "",
);
const packageMutation = useCompanyParticipationPackageMutation();
packageMutation.companyId.value = props.companyId;

const { toast } = useToast();

const { data: eventsData } = useQuery({
  key: () => ["events"],
  query: () => getAllEvents(),
});

const { data: packagesData, isLoading: isPackageLoading } = usePackagesQuery();

const { data: membersData } = useQuery({
  key: () => ["members"],
  query: () => getAllMembers(),
});

const packageOptions = computed(() => {
  const allPkgs = (packagesData.value || []) as Package[];
  const eventId = props.participation?.event;
  if (!eventId) return [];

  const ev = eventsData.value?.data?.find((e) => e.id === eventId);
  if (!ev) return allPkgs.map((p) => ({ id: String(p.id), name: p.name }));

  const name = String(ev.name || "");
  const pkgs = allPkgs.filter((ap) => String(ap.name || "").startsWith(name));

  return pkgs.map((p) => ({
    id: String(p.id),
    name: p.name || "(no name)",
  }));
});

const currentPackageId = computed(() =>
  props.participation.package ? String(props.participation.package) : "",
);
const pkgQuery = usePackageQuery(currentPackageId);
const packageName = computed(() => {
  if (!currentPackageId.value) return null;
  const pkgFromList = (packagesData.value as Package[] | undefined)?.find(
    (p) => String(p.id) === currentPackageId.value,
  );
  if (pkgFromList) return pkgFromList.name;
  return pkgQuery.data.value?.name || null;
});

const startEditing = () => {
  // entering edit mode for participation
  isEditing.value = true;
  editForm.member = props.participation.member;
  editForm.partner = props.participation.partner;
  // If no confirmed date exists, set it to current time, otherwise convert existing date
  const confirmedDate = props.participation.confirmed;
  editForm.confirmed = formatToDatetimeLocal(confirmedDate);
  editForm.notes = props.participation.notes;
  selectedPackageId.value = props.participation.package
    ? String(props.participation.package)
    : "";
};

watch(
  () => props.participation.package,
  (newVal) => {
    if (!isEditing.value) {
      selectedPackageId.value = newVal ? String(newVal) : "";
    }
  },
);

const cancelEditing = () => {
  isEditing.value = false;
  selectedPackageId.value = props.participation.package
    ? String(props.participation.package)
    : "";
};

const saveChanges = async () => {
  isSaving.value = true;

  try {
    const currentPkgId = props.participation.package
      ? String(props.participation.package)
      : "";
    const packageChanged =
      selectedPackageId.value && selectedPackageId.value !== currentPkgId;

    if (packageChanged) {
      packageMutation.companyId.value = props.companyId;
      packageMutation.packageId.value = selectedPackageId.value;
      await packageMutation.mutateAsync();
    }

    const dataToSend = {
      ...editForm,
      confirmed: convertDatetimeLocalToISO(editForm.confirmed!),
    };

    updateMutation.companyId.value = props.companyId;
    updateMutation.data.value = dataToSend;
    await updateMutation.mutateAsync();

    toast.success({
      title: "Participation updated",
      description: "Company participation has been updated successfully.",
    });

    isEditing.value = false;
  } catch (error) {
    console.error("Failed to update company participation:", error);
    toast.error({
      title: "Failed to update participation",
      description: "Could not update company participation. Please try again.",
    });
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
