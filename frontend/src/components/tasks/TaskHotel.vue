<template>
  <TaskTimelineItem
    :step-number="stepNumber"
    title="Hotel"
    :is-complete="isComplete"
    :is-last="isLast"
  >
    <template #icon>
      <Hotel class="w-4 h-4" />
    </template>
    <template #header-actions>
      <StatusToggleBadge
        v-model="hasRequestedHotelInfo"
        active-label="Requested"
        inactive-label="Not Requested"
        description="Mark whether you've asked the speaker for hotel info."
      />
    </template>

    <div class="space-y-4">
      <div class="flex items-center space-x-2">
        <Checkbox id="hotel-booked" v-model="hotelBooked" />
        <Label for="hotel-booked" class="text-sm"> Hotel booked </Label>
      </div>
    </div>
  </TaskTimelineItem>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
import TaskTimelineItem from "./TaskTimelineItem.vue";
import StatusToggleBadge from "./StatusToggleBadge.vue";
import { Checkbox } from "@/components/ui/checkbox";
import { Label } from "@/components/ui/label";
import { Hotel } from "lucide-vue-next";

interface Props {
  entityId: string;
  stepNumber?: number;
  isLast?: boolean;
}

withDefaults(defineProps<Props>(), {
  stepNumber: 6,
  isLast: false,
});

// Hotel states
const hasRequestedHotelInfo = ref<boolean>(false);
const hotelBooked = ref<boolean>(false);

const isComplete = computed(() => {
  return hotelBooked.value === true;
});

defineExpose({
  isComplete,
});
</script>
