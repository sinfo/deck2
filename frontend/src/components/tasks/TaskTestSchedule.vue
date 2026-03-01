<template>
  <TaskTimelineItem
    :step-number="stepNumber"
    title="Test Schedule"
    :is-complete="isComplete"
    :is-last="isLast"
  >
    <template #icon>
      <ClipboardCheck class="w-4 h-4" />
    </template>

    <div class="space-y-4">
      <div class="space-y-2">
        <Label for="test-schedule" class="text-sm">Scheduled Time</Label>
        <Input
          id="test-schedule"
          v-model="testSchedule"
          placeholder="e.g. Monday 14:00"
        />
      </div>

      <div class="flex items-center space-x-2">
        <Checkbox id="test-done" v-model="testDone" />
        <Label for="test-done" class="text-sm">Test completed</Label>
      </div>
    </div>
  </TaskTimelineItem>
</template>

<script setup lang="ts">
import { ref, computed, watch } from "vue";
import TaskTimelineItem from "./TaskTimelineItem.vue";
import { Checkbox } from "@/components/ui/checkbox";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { ClipboardCheck } from "lucide-vue-next";
import type { SpeakerTasks } from "@/dto/tasks";

interface Props {
  entityId: string;
  stepNumber?: number;
  isLast?: boolean;
  speakerTasks?: SpeakerTasks;
}

const props = withDefaults(defineProps<Props>(), {
  stepNumber: 8,
  isLast: false,
  speakerTasks: undefined,
});

const emit = defineEmits<{
  "update:testSchedule": [schedule: string, done: boolean];
}>();

const testSchedule = ref<string>(
  props.speakerTasks?.materials?.testSchedule ?? "",
);
const testDone = ref<boolean>(props.speakerTasks?.materials?.testDone ?? false);

watch([testSchedule, testDone], () => {
  emit("update:testSchedule", testSchedule.value, testDone.value);
});

const isComplete = computed(() => testDone.value === true);

defineExpose({ isComplete });
</script>
