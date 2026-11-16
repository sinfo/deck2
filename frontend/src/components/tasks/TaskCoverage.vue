<template>
  <TaskTimelineItem
    :step-number="stepNumber"
    title="Coverage"
    :is-complete="isComplete"
  >
    <template #icon>
      <Camera class="w-4 h-4" />
    </template>

    <div class="space-y-4">
      <div class="space-y-3">
        <span class="text-sm font-medium">Video</span>
        <div class="flex flex-wrap gap-4">
          <div class="space-y-1">
            <Label class="text-xs">Video Coverage</Label>
            <Select v-model="videoCoverage">
              <SelectTrigger class="w-[160px]">
                <SelectValue placeholder="Select" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="not_responded">Didn't respond</SelectItem>
                <SelectItem value="yes">Yes</SelectItem>
                <SelectItem value="no">No</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div class="space-y-1">
            <Label class="text-xs">Streaming</Label>
            <Select v-model="streaming">
              <SelectTrigger class="w-[160px]">
                <SelectValue placeholder="Select" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="not_responded">Didn't respond</SelectItem>
                <SelectItem value="yes">Yes</SelectItem>
                <SelectItem value="no">No</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
      </div>

      <Separator />

      <div class="space-y-3">
        <span class="text-sm font-medium">Photo</span>
        <div class="space-y-1">
          <Label class="text-xs">Photo Coverage</Label>
          <Select v-model="photoCoverage">
            <SelectTrigger class="w-[160px]">
              <SelectValue placeholder="Select" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="not_responded">Didn't respond</SelectItem>
              <SelectItem value="yes">Yes</SelectItem>
              <SelectItem value="no">No</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>
    </div>
  </TaskTimelineItem>
</template>

<script setup lang="ts">
import { ref, computed, watch } from "vue";
import TaskTimelineItem from "./TaskTimelineItem.vue";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Camera } from "lucide-vue-next";
import type { SpeakerTasks, SpeakerTaskCoverage } from "@/dto/tasks";

interface Props {
  entityId: string;
  stepNumber?: number;
  speakerTasks?: SpeakerTasks;
}

const props = withDefaults(defineProps<Props>(), {
  stepNumber: 4,
  speakerTasks: undefined,
});

const emit = defineEmits<{
  "update:coverage": [value: SpeakerTaskCoverage];
}>();

type CoverageValue = "not_responded" | "yes" | "no";

const videoCoverage = ref<CoverageValue>(
  (props.speakerTasks?.coverage?.video as CoverageValue) ?? "not_responded",
);
const streaming = ref<CoverageValue>(
  (props.speakerTasks?.coverage?.streaming as CoverageValue) ?? "not_responded",
);
const photoCoverage = ref<CoverageValue>(
  (props.speakerTasks?.coverage?.photo as CoverageValue) ?? "not_responded",
);

watch([videoCoverage, streaming, photoCoverage], () => {
  emit("update:coverage", {
    video: videoCoverage.value,
    streaming: streaming.value,
    photo: photoCoverage.value,
  });
});

const isComplete = computed(() => {
  return (
    videoCoverage.value !== "not_responded" &&
    streaming.value !== "not_responded" &&
    photoCoverage.value !== "not_responded"
  );
});

defineExpose({
  isComplete,
});
</script>
