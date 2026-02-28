<template>
  <TaskTimelineItem
    :step-number="stepNumber"
    title="Materials"
    :is-complete="isComplete"
  >
    <template #icon>
      <Package class="w-4 h-4" />
    </template>
    <template #header-actions>
      <StatusToggleBadge
        v-model="hasRequestedMaterials"
        active-label="Requested"
        inactive-label="Not Requested"
        description="Mark whether you've asked the speaker for materials."
      />
    </template>

    <div class="space-y-4">
      <div class="flex items-center space-x-2">
        <Checkbox id="materials-received" v-model="materialsReceived" />
        <Label for="materials-received" class="text-sm">
          Materials received
        </Label>
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
import { Package } from "lucide-vue-next";

interface Props {
  entityId: string;
  stepNumber?: number;
}

withDefaults(defineProps<Props>(), {
  stepNumber: 5,
});

// Materials states
const hasRequestedMaterials = ref<boolean>(false);
const materialsReceived = ref<boolean>(false);

const isComplete = computed(() => {
  return materialsReceived.value === true;
});

defineExpose({
  isComplete,
});
</script>
