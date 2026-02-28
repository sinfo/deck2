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

        <div class="flex items-center space-x-2">
          <Checkbox id="video-coverage" v-model="videoCoverage" />
          <Label for="video-coverage" class="text-sm">
            Video coverage confirmed
          </Label>
        </div>

        <div class="flex items-center space-x-2">
          <Checkbox id="streaming" v-model="streaming" />
          <Label for="streaming" class="text-sm"> Streaming confirmed </Label>
        </div>
      </div>

      <Separator />

      <div class="space-y-3">
        <span class="text-sm font-medium">Photo</span>

        <div class="flex items-center space-x-2">
          <Checkbox id="photo-coverage" v-model="photoCoverage" />
          <Label for="photo-coverage" class="text-sm">
            Photo coverage confirmed
          </Label>
        </div>
      </div>
    </div>
  </TaskTimelineItem>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
import TaskTimelineItem from "./TaskTimelineItem.vue";
import { Checkbox } from "@/components/ui/checkbox";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import { Camera } from "lucide-vue-next";

interface Props {
  entityId: string;
  stepNumber?: number;
}

withDefaults(defineProps<Props>(), {
  stepNumber: 5,
});

// Coverage states
const videoCoverage = ref<boolean>(false);
const streaming = ref<boolean>(false);
const photoCoverage = ref<boolean>(false);

const isComplete = computed(() => {
  return (
    videoCoverage.value === true &&
    streaming.value === true &&
    photoCoverage.value === true
  );
});

defineExpose({
  isComplete,
});
</script>
