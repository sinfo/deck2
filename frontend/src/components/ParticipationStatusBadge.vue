<template>
  <Popover :open="isStatusMenuOpen" @update:open="isStatusMenuOpen = $event">
    <PopoverTrigger as-child>
      <Badge
        :class="participationStatusColor[currentStatus]?.background"
        class="text-xs flex items-center gap-1 cursor-pointer"
      >
        {{ humanReadableParticipationStatus[currentStatus] }}
        <Loader2 v-if="isUpdating" class="w-3 h-3 animate-spin" />
        <ChevronDown v-else class="w-3 h-3" />
      </Badge>
    </PopoverTrigger>
    <PopoverContent class="w-56 p-0 z-50">
      <div class="flex flex-col">
        <button
          v-for="(label, value) in humanReadableParticipationStatus"
          :key="value"
          :class="[
            'px-3 py-2 text-sm text-left hover:bg-accent cursor-pointer',
            currentStatus === value && 'bg-accent',
          ]"
          :disabled="isUpdating"
          @click="selectStatus(value as ParticipationStatus)"
        >
          {{ label }}
        </button>
      </div>
    </PopoverContent>
  </Popover>
</template>

<script setup lang="ts">
import { ref, watch } from "vue";
import {
  humanReadableParticipationStatus,
  participationStatusColor,
  type ParticipationStatus,
} from "@/dto";
import { Badge } from "@/components/ui/badge";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { ChevronDown, Loader2 } from "lucide-vue-next";

interface Props {
  status: ParticipationStatus;
  entityId: string;
  entityType: "company" | "speaker";
}

const props = defineProps<Props>();

const emit = defineEmits<{
  "update:status": [status: ParticipationStatus];
  updated: [];
}>();

const isStatusMenuOpen = ref(false);
const isUpdating = ref(false);
const currentStatus = ref<ParticipationStatus>(props.status);

// Sync currentStatus when props change (e.g., after query refetch)
watch(
  () => props.status,
  (newStatus) => {
    currentStatus.value = newStatus;
  },
);

// Import mutations dynamically based on entity type
import { useCompanyParticipationStatusMutation } from "@/mutations/companies";
import { useSpeakerParticipationStatusMutation } from "@/mutations/speakers";

const companyStatusMutation = useCompanyParticipationStatusMutation();
const speakerStatusMutation = useSpeakerParticipationStatusMutation();

const selectStatus = async (status: ParticipationStatus) => {
  const previous = currentStatus.value;
  currentStatus.value = status;
  isStatusMenuOpen.value = false;

  try {
    isUpdating.value = true;

    if (props.entityType === "company") {
      companyStatusMutation.companyId.value = props.entityId;
      await companyStatusMutation.mutateAsync(status);
    } else {
      speakerStatusMutation.speakerId.value = props.entityId;
      await speakerStatusMutation.mutateAsync(status);
    }

    emit("update:status", status);
    emit("updated");
  } catch (err) {
    console.error("Failed to update participation status:", err);
    currentStatus.value = previous;
  } finally {
    isUpdating.value = false;
  }
};
</script>
