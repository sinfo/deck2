<template>
  <StepperItem
    :step="stepNumber"
    class="flex gap-4 items-stretch"
    :completed="!isComplete"
  >
    <div class="flex flex-col items-center">
      <StepperIndicator class="shrink-0">
        <slot name="icon" />
      </StepperIndicator>
      <StepperSeparator
        v-if="!isLast"
        class="flex-1 w-0.5 min-h-4 my-1 !bg-muted"
      />
    </div>
    <div class="flex-1" :class="{ 'pb-4': !isLast }">
      <Collapsible v-model:open="isOpen" class="w-full">
        <Card class="p-4">
          <div
            class="flex items-center justify-between cursor-pointer"
            @click="isOpen = !isOpen"
          >
            <h3 class="font-medium flex items-center gap-2">
              {{ title }}
              <Loader2
                v-if="isSaving"
                class="w-3 h-3 animate-spin text-muted-foreground"
              />
            </h3>
            <div class="flex items-center gap-2">
              <div @click.stop>
                <slot name="header-actions" />
              </div>
              <Badge v-if="isComplete" variant="default"> Complete </Badge>
              <Badge v-else variant="secondary"> Pending </Badge>
              <ChevronDown
                class="h-4 w-4 transition-transform duration-200"
                :class="{ 'rotate-180': isOpen }"
              />
            </div>
          </div>
          <CollapsibleContent class="mt-4">
            <div :class="{ 'pointer-events-none opacity-50': isSaving }">
              <slot />
            </div>
          </CollapsibleContent>
        </Card>
      </Collapsible>
    </div>
  </StepperItem>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Collapsible, CollapsibleContent } from "@/components/ui/collapsible";
import {
  StepperItem,
  StepperIndicator,
  StepperSeparator,
} from "@/components/ui/stepper";
import { ChevronDown, Loader2 } from "lucide-vue-next";
import { inject } from "vue";
import { TASKS_SAVING_KEY } from "@/composables/useTasksSaving";

interface Props {
  stepNumber: number;
  title: string;
  isComplete: boolean;
  isLast?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  isLast: false,
});

// Injected from Tasks.vue — undefined outside the tasks context
const isSaving = inject(TASKS_SAVING_KEY);

// Start collapsed if complete, open if incomplete
const isOpen = ref(!props.isComplete);
</script>
