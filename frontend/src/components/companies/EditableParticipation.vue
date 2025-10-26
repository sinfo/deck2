<template>
  <Card class="p-4">
    <div class="space-y-4">
      <div class="flex items-center justify-between">
        <h4 class="font-medium">
          {{ getEventName(participation.event) }}
        </h4>
        <div class="flex items-center gap-2">
          <Popover :open="isEditing && isStatusMenuOpen" @update:open="isStatusMenuOpen = $event">
            <PopoverTrigger as-child>
              <Badge
                  :class="participationStatusColor[selectedStatus]?.background"
                  class="text-xs flex items-center gap-1 cursor-pointer"
              >
                {{ humanReadableParticipationStatus[selectedStatus] }}
                <ChevronDown v-if="isEditing" class="w-3 h-3" />
              </Badge>
            </PopoverTrigger>
            <PopoverContent class="w-56 p-0">
              <div class="flex flex-col">
                <button
                    v-for="(label, value) in humanReadableParticipationStatus"
                    :key="value"
                    @click="selectStatus(value as ParticipationStatus)"
                    :class="[
          'px-3 py-2 text-sm text-left hover:bg-accent cursor-pointer',
          selectedStatus === value && 'bg-accent'
        ]"
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
            <Button size="sm" @click="saveChanges" :disabled="isSaving">
              {{ isSaving ? "Saving..." : "Save" }}
            </Button>
            <Button variant="outline" size="sm" @click="cancelEditing">
              Cancel
            </Button>
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
              {{ formatDate(participation.confirmed) }}
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
import { ref, reactive } from "vue";
import { useQuery } from "@pinia/colada";
import { getAllEvents } from "@/api/events";
import { getAllMembers } from "@/api/members";
import {useCompanyParticipationMutation, useCompanyParticipationStatusMutation} from "@/mutations/companies";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import MemberSelect from "@/components/members/MemberSelect.vue";
import type {
  CompanyParticipation,
  UpdateCompanyParticipationData,
} from "@/dto/companies";
import {
  humanReadableParticipationStatus, type ParticipationStatus,
  participationStatusColor,
} from "@/dto";
import { ChevronDown } from "lucide-vue-next";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import Image from "../Image.vue";

interface Props {
  participation: CompanyParticipation;
  companyId: string;
}

const props = defineProps<Props>();

const isEditing = ref(false);
const isSaving = ref(false);
const isStatusMenuOpen = ref(false);
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

const { data: eventsData } = useQuery({
  key: () => ["events"],
  query: () => getAllEvents(),
});

const { data: membersData } = useQuery({
  key: () => ["members"],
  query: () => getAllMembers(),
});

const selectStatus = (status: ParticipationStatus) => {
  selectedStatus.value = status;
  isStatusMenuOpen.value = false;
};

const startEditing = () => {
  isEditing.value = true;
  selectedStatus.value = props.participation.status;
  editForm.member = props.participation.member;
  editForm.partner = props.participation.partner;
  // If no confirmed date exists, set it to current time, otherwise convert existing date
  const confirmedDate = props.participation.confirmed;
  editForm.confirmed = formatToDatetimeLocal(confirmedDate);
  editForm.notes = props.participation.notes;
};

const cancelEditing = () => {
  isEditing.value = false;
};

const saveChanges = async () => {
  isSaving.value = true;

  try {
    if (selectedStatus.value !== props.participation.status) {
      statusMutation.mutate(selectedStatus.value);
    }

    const dataToSend = {
      ...editForm,
      confirmed: convertDatetimeLocalToISO(editForm.confirmed!)
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
