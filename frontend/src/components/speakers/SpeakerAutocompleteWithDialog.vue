<template>
  <div>
    <!-- Speaker Autocomplete -->
    <SpeakerAutocomplete
      :model-value="modelValue"
      :label="label"
      :placeholder="placeholder"
      :disabled="disabled"
      :event-id="eventId"
      show-create
      @selected="(speaker: Speaker) => $emit('selected', speaker)"
      @update:model-value="(value: string) => $emit('update:modelValue', value)"
      @create-speaker="handleCreateSpeaker"
    />

    <!-- Create Speaker Dialog -->
    <Teleport to="body">
      <AlertDialog v-model:open="isDialogOpen">
        <AlertDialogContent
          class="max-w-2xl max-h-[90vh] overflow-hidden flex flex-col"
        >
          <AlertDialogHeader class="flex-shrink-0">
            <AlertDialogTitle>Create New Speaker</AlertDialogTitle>
            <AlertDialogDescription>
              Fill out the information below to create a new speaker.
            </AlertDialogDescription>
          </AlertDialogHeader>

          <div class="flex-1 overflow-y-auto min-h-0">
            <CreateSpeakerForm
              :initial-speaker-name="searchTerm"
              @cancel="handleCancel"
              @success="handleSuccess"
            />
          </div>
        </AlertDialogContent>
      </AlertDialog>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import SpeakerAutocomplete from "./SpeakerAutocomplete.vue";
import CreateSpeakerForm from "./CreateSpeakerForm.vue";
import {
  AlertDialog,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import type { Speaker } from "@/dto/speakers";

interface Props {
  modelValue?: string;
  label?: string;
  placeholder?: string;
  disabled?: boolean;
  eventId?: number;
}

defineProps<Props>();

const emit = defineEmits<{
  selected: [value: Speaker];
  "update:modelValue": [value: string];
  success: [speakerId: string];
}>();

const isDialogOpen = ref(false);
const searchTerm = ref("");

const handleCreateSpeaker = (term: string) => {
  searchTerm.value = term;
  isDialogOpen.value = true;
};

const handleCancel = () => {
  isDialogOpen.value = false;
  searchTerm.value = ""; // Clear search term when dialog is closed
};

const handleSuccess = (speakerId: string) => {
  isDialogOpen.value = false;
  searchTerm.value = ""; // Clear search term when dialog is closed
  emit("success", speakerId);
};
</script>
