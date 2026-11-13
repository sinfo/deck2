<template>
  <TaskTimelineItem
    :step-number="stepNumber"
    title="Corlief"
    :is-complete="isComplete"
  >
    <template #icon>
      <Building2 class="w-4 h-4" />
    </template>
    <div class="space-y-4">
      <div class="flex items-center space-x-2">
        <Checkbox id="corlief-pre-notice" v-model="hasPreNotice" />
        <Label for="corlief-pre-notice" class="text-sm">Pre notice</Label>
      </div>

      <div class="flex items-center space-x-2">
        <Checkbox id="corlief-scheduled" v-model="hasScheduled" />
        <Label for="corlief-scheduled" class="text-sm">Scheduled</Label>
      </div>

      <div class="flex items-center space-x-2">
        <Checkbox id="corlief-reserved" v-model="hasReserved" />
        <Label for="corlief-reserved" class="text-sm">Company reserved</Label>
      </div>
    </div>
  </TaskTimelineItem>
</template>

<script setup lang="ts">
import { ref, computed, watch } from "vue";
import TaskTimelineItem from "./TaskTimelineItem.vue";
import { Checkbox } from "@/components/ui/checkbox";
import { Label } from "@/components/ui/label";
import { Building2 } from "lucide-vue-next";
import type { CompanyTasks, CompanyTaskCorlief } from "@/dto/tasks";

interface Props {
  entityId: string;
  stepNumber?: number;
  companyTasks?: CompanyTasks;
}

const props = withDefaults(defineProps<Props>(), {
  stepNumber: 5,
  companyTasks: undefined,
});

const emit = defineEmits<{
  "update:corlief": [value: CompanyTaskCorlief];
}>();

// Corlief states
const hasPreNotice = ref<boolean>(
  props.companyTasks?.corlief?.preNotice ?? false,
);
const hasScheduled = ref<boolean>(
  props.companyTasks?.corlief?.scheduled ?? false,
);
const hasReserved = ref<boolean>(
  props.companyTasks?.corlief?.reserved ?? false,
);

watch([hasPreNotice, hasScheduled, hasReserved], () => {
  emit("update:corlief", {
    preNotice: hasPreNotice.value,
    scheduled: hasScheduled.value,
    reserved: hasReserved.value,
  });
});

const isComplete = computed(() => {
  return (
    hasPreNotice.value === true &&
    hasScheduled.value === true &&
    hasReserved.value === true
  );
});

defineExpose({
  isComplete,
});
</script>
