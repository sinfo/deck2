<template>
  <TaskTimelineItem
    :step-number="4"
    title="Session Titles"
    :is-complete="isComplete"
  >
    <template #icon>
      <Presentation class="w-4 h-4" />
    </template>
    <div class="space-y-4">
      <!-- Presentation Title (if package includes presentation item) -->
      <div v-if="hasPresentation" class="space-y-2">
        <Label for="presentation-title">Presentation Title</Label>
        <Input
          id="presentation-title"
          v-model="presentationTitle"
          placeholder="Enter presentation title"
          :class="{ 'border-destructive': isPresentationTitleTooLong }"
        />
        <div class="flex items-center justify-between">
          <p
            v-if="isPresentationTitleTooLong"
            class="text-xs text-destructive flex items-center gap-1"
          >
            <AlertTriangle class="w-3 h-3" />
            Title exceeds 30 characters ({{ presentationTitle.length }}/30)
          </p>
          <p v-else class="text-xs text-muted-foreground">
            {{ presentationTitle.length }}/30 characters
          </p>
        </div>
      </div>

      <!-- Workshop Title (if package includes workshop item) -->
      <div v-if="hasWorkshop" class="space-y-2">
        <Label for="workshop-title">Workshop Title</Label>
        <Input
          id="workshop-title"
          v-model="workshopTitle"
          placeholder="Enter workshop title"
          :class="{ 'border-destructive': isWorkshopTitleTooLong }"
        />
        <div class="flex items-center justify-between">
          <p
            v-if="isWorkshopTitleTooLong"
            class="text-xs text-destructive flex items-center gap-1"
          >
            <AlertTriangle class="w-3 h-3" />
            Title exceeds 30 characters ({{ workshopTitle.length }}/30)
          </p>
          <p v-else class="text-xs text-muted-foreground">
            {{ workshopTitle.length }}/30 characters
          </p>
        </div>
      </div>
    </div>
  </TaskTimelineItem>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { AlertTriangle, Presentation } from "lucide-vue-next";
import TaskTimelineItem from "./TaskTimelineItem.vue";
import type { Item } from "@/dto/item";

interface Props {
  packageItems: Item[];
}

const props = defineProps<Props>();

// Check if package includes presentation or workshop items by type
const hasPresentation = computed(() =>
  props.packageItems.some(
    (item) => item.name?.toLowerCase() === "presentation",
  ),
);
const hasWorkshop = computed(() =>
  props.packageItems.some((item) => item.name?.toLowerCase() === "workshop"),
);

// Session titles
const presentationTitle = ref("");
const workshopTitle = ref("");

const isPresentationTitleTooLong = computed(
  () => presentationTitle.value.length > 30,
);
const isWorkshopTitleTooLong = computed(() => workshopTitle.value.length > 30);

// Completion state
const isComplete = computed(() => {
  const presentationComplete =
    !hasPresentation.value ||
    (presentationTitle.value.length > 0 && !isPresentationTitleTooLong.value);
  const workshopComplete =
    !hasWorkshop.value ||
    (workshopTitle.value.length > 0 && !isWorkshopTitleTooLong.value);
  return presentationComplete && workshopComplete;
});

defineExpose({
  isComplete,
});
</script>
