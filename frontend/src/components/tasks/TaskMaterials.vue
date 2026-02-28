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
      <!-- Talk Info -->
      <div class="space-y-3">
        <span class="text-sm font-medium">Talk Info</span>

        <div class="space-y-2">
          <Label for="talk-title" class="text-sm">Talk Title</Label>
          <Input
            id="talk-title"
            v-model="talkTitle"
            placeholder="Title of the talk"
          />
        </div>

        <div class="space-y-2">
          <Label for="talk-description" class="text-sm">
            Talk Description
          </Label>
          <Textarea
            id="talk-description"
            v-model="talkDescription"
            placeholder="Description of the talk"
            :rows="3"
          />
        </div>
      </div>

      <Separator />

      <!-- Materials -->
      <div class="space-y-3">
        <span class="text-sm font-medium">Materials</span>

        <div class="flex items-center space-x-2">
          <Checkbox id="materials-received" v-model="materialsReceived" />
          <Label for="materials-received" class="text-sm">
            Materials received
          </Label>
        </div>
      </div>

      <Separator />

      <!-- Test Schedule -->
      <div class="space-y-3">
        <span class="text-sm font-medium">Test Schedule</span>

        <div class="space-y-2">
          <Label for="test-schedule" class="text-sm">Schedule</Label>
          <Input
            id="test-schedule"
            v-model="testSchedule"
            placeholder="e.g. Monday 14:00"
          />
        </div>

        <div class="flex items-center space-x-2">
          <Checkbox id="test-done" v-model="testDone" />
          <Label for="test-done" class="text-sm"> Test completed </Label>
        </div>
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
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Separator } from "@/components/ui/separator";
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

// Talk info
const talkTitle = ref<string>("");
const talkDescription = ref<string>("");

// Test schedule
const testSchedule = ref<string>("");
const testDone = ref<boolean>(false);

const isComplete = computed(() => {
  return materialsReceived.value === true && testDone.value === true;
});

defineExpose({
  isComplete,
});
</script>
