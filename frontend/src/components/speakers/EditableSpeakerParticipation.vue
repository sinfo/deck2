<template>
  <Card class="p-4">
    <div class="space-y-4">
      <div class="flex items-center justify-between">
        <h4 class="font-medium">
          {{ getEventName(participation.event) }}
        </h4>
        <div class="flex items-center gap-2">
          <Badge
            :class="participationStatusColor[participation.status]?.background"
            class="text-xs"
          >
            {{ humanReadableParticipationStatus[participation.status] }}
          </Badge>
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

          <div v-if="participation.feedback" class="text-sm">
            <span class="font-medium">Feedback:</span>
            <div class="mt-1 text-muted-foreground">
              {{ participation.feedback }}
            </div>
          </div>

          <div
            v-if="
              participation.room &&
              (participation.room.type ||
                participation.room.cost ||
                participation.room.notes)
            "
          >
            <h5 class="text-sm font-medium">Room Details:</h5>
            <div class="flex flex-row gap-2 items-start">
              <Badge v-if="participation.room.type" class="text-xs">
                {{ participation.room.type }}
              </Badge>

              <Badge
                v-if="participation.room.cost"
                class="text-xs bg-amber-400"
              >
                {{ participation.room.cost }}€
              </Badge>
            </div>

            <div v-if="participation.room.notes">
              <div class="mt-1 text-muted-foreground">
                {{ participation.room.notes }}
              </div>
            </div>
          </div>
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
            <Label for="feedback">Feedback</Label>
            <textarea
              id="feedback"
              v-model="editForm.feedback"
              rows="3"
              class="w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-vertical"
              placeholder="Add feedback..."
            />
          </div>

          <div class="space-y-2">
            <Label for="room-details">Room Details</Label>
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-2">
              <div class="space-y-2">
                <Label for="room-type">Type</Label>
                <input
                  id="room-type"
                  v-model="editForm.room!.type"
                  type="text"
                  class="w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="e.g., Single, Double, Suite"
                />
              </div>

              <div class="space-y-2">
                <Label for="room-cost">Cost</Label>
                <input
                  id="room-cost"
                  v-model.number="editForm.room!.cost"
                  type="number"
                  min="0"
                  step="0.01"
                  class="w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="0.00"
                />
              </div>
            </div>

            <div class="space-y-2">
              <Label for="room-notes">Notes</Label>
              <textarea
                id="room-notes"
                v-model="editForm.room!.notes"
                rows="2"
                class="w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-vertical"
                placeholder="Additional room notes..."
              />
            </div>
          </div>
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
import { useSpeakerParticipationMutation } from "@/mutations/speakers";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import MemberSelect from "@/components/members/MemberSelect.vue";
import type {
  SpeakerParticipation,
  UpdateSpeakerParticipationData,
} from "@/dto/speakers";
import {
  humanReadableParticipationStatus,
  participationStatusColor,
} from "@/dto";
import Image from "../Image.vue";

interface Props {
  participation: SpeakerParticipation;
  speakerId: string;
}

const props = defineProps<Props>();
const isEditing = ref(false);
const isSaving = ref(false);

const editForm = reactive<UpdateSpeakerParticipationData>({
  member: props.participation.member,
  feedback: props.participation.feedback,
  room: {
    type: props.participation.room?.type || "",
    cost: props.participation.room?.cost || 0,
    notes: props.participation.room?.notes || "",
  },
});

const { data: eventsData } = useQuery({
  key: () => ["events"],
  query: () => getAllEvents(),
});

const { data: membersData } = useQuery({
  key: () => ["members"],
  query: () => getAllMembers(),
});

const updateMutation = useSpeakerParticipationMutation();

updateMutation.speakerId.value = props.speakerId;

const startEditing = () => {
  isEditing.value = true;
  // Reset form to current values
  editForm.member = props.participation.member;
  editForm.feedback = props.participation.feedback;
  editForm.room = {
    type: props.participation.room?.type || "",
    cost: props.participation.room?.cost || 0,
    notes: props.participation.room?.notes || "",
  };
};

const cancelEditing = () => {
  isEditing.value = false;
};

const saveChanges = async () => {
  isSaving.value = true;

  try {
    await updateMutation.mutate(editForm);
    isEditing.value = false;
    isSaving.value = false;
  } catch (error) {
    isSaving.value = false;
    console.error("Failed to update speaker participation:", error);
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
</script>
