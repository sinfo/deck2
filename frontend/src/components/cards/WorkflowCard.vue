<script setup lang="ts">
import { Card, CardContent, CardHeader, CardTitle } from "../ui/card";
import Image from "../Image.vue";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "../ui/select";
import { computed, watch, type Component } from "vue";
import {
  humanReadableParticipationStatus,
  participationNextValues,
  participationStatusColor,
  type ParticipationStatus,
} from "@/dto";
import type { RouteLocationRaw } from "vue-router";
import { useConfetti } from "@/composables/useConfetti";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "../ui/tooltip";
import { Loader2 } from "lucide-vue-next";

export interface WorkflowBadge {
  icon: Component;
  label: string;
  color?: string;
  bgColor?: string;
}

const props = defineProps<{
  title: string;
  currentStatus?: ParticipationStatus;
  image?: string;
  isLoading?: boolean;
  badges?: WorkflowBadge[];
  to?: RouteLocationRaw;
}>();

// Singleton confetti – only one explosion + sound across all cards
const { trigger: triggerConfetti } = useConfetti();

const selectedStatus = computed({
  get: () => props.currentStatus || "SUGGESTED",
  set: (value: number) => {
    emits("statusChange", value);
  },
});

const emits = defineEmits<{
  (e: "statusChange", step: number): void;
}>();

const possibleStates = computed(
  () => participationNextValues[selectedStatus.value] || [],
);

// Watch for status changes to trigger confetti
watch(
  () => props.currentStatus,
  (newStatus, oldStatus) => {
    if (oldStatus && newStatus && oldStatus !== newStatus) {
      if (newStatus === "ACCEPTED" || newStatus === "ANNOUNCED") {
        triggerConfetti();
      }
    }
  },
  { immediate: false },
);
</script>

<template>
  <component
    :is="props.to ? 'RouterLink' : 'div'"
    :to="props.to"
    :class="['block', props.to ? 'cursor-pointer' : '']"
  >
    <Card
      :class="[
        'ring',
        'h-full',
        'relative',
        participationStatusColor[selectedStatus].ring,
      ]"
    >
      <CardContent>
        <div
          v-if="!possibleStates.length"
          :class="[
            'w-full flex items-center rounded-md border px-3 py-2 text-sm shadow-xs pointer-events-none',
            participationStatusColor[selectedStatus].background,
          ]"
        >
          {{ humanReadableParticipationStatus[selectedStatus] }}
        </div>
        <Select
          v-else
          v-model="selectedStatus"
          class="relative z-10"
          :disabled="isLoading"
        >
          <SelectTrigger
            :class="[
              'w-full',
              participationStatusColor[selectedStatus].background,
            ]"
          >
            <SelectValue placeholder="State">
              <span class="flex items-center gap-2">
                {{ humanReadableParticipationStatus[selectedStatus] }}
                <Loader2 v-if="isLoading" class="w-3 h-3 animate-spin" />
              </span>
            </SelectValue>
          </SelectTrigger>
          <SelectContent>
            <SelectItem
              v-for="(state, i) in possibleStates"
              :key="state"
              :value="i + 1"
            >
              {{ humanReadableParticipationStatus[state] }}
            </SelectItem>
          </SelectContent>
        </Select>

        <div class="block w-full">
          <Image
            :src="image"
            class="w-full h-32 object-contain rounded-lg pt-2"
          />
        </div>
      </CardContent>
      <CardHeader>
        <CardTitle>{{ title }}</CardTitle>
        <div v-if="badges?.length" class="flex flex-wrap gap-1">
          <TooltipProvider v-for="badge in badges" :key="badge.label">
            <Tooltip>
              <TooltipTrigger as-child>
                <div
                  class="inline-flex items-center justify-center w-6 h-6 rounded-full transition-colors"
                  :class="badge.bgColor || 'bg-muted hover:bg-muted/80'"
                >
                  <component
                    :is="badge.icon"
                    class="w-3.5 h-3.5"
                    :class="badge.color || 'text-muted-foreground'"
                  />
                </div>
              </TooltipTrigger>
              <TooltipContent>
                <p>{{ badge.label }}</p>
              </TooltipContent>
            </Tooltip>
          </TooltipProvider>
        </div>
      </CardHeader>
    </Card>
  </component>
</template>
