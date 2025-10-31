<template>
  <div
    ref="toolbar"
    class="flex flex-wrap gap-3 my-4 items-center"
    role="toolbar"
    aria-label="Participation status filters"
    @keydown="onToolbarKeydown"
  >
    <!-- All chip -->
    <button
      :ref="(el) => setButtonRef(el, 0)"
      type="button"
      :aria-pressed="selected === null"
      title="Show all participations"
      :tabindex="focusedIndex === 0 ? 0 : -1"
      :class="[
        'inline-flex items-center gap-2 px-4 py-1 rounded-full text-sm transition duration-150 ease-out cursor-pointer select-none transform-gpu',
        selected === null
          ? 'bg-black/5 text-slate-900 font-semibold ring-2 ring-offset-1 ring-slate-300'
          : 'bg-white text-slate-700 hover:bg-slate-50',
        // make focus with keyboard very visible
        'focus-visible:scale-105 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-slate-400',
      ]"
      @click="setSelected(null)"
      @focus="focusedIndex = 0"
      @keydown="onButtonKeydown"
    >
      <Check
        v-if="selected === null"
        class="w-4 h-4 text-slate-900 stroke-current"
        aria-hidden="true"
      />
      <span>All</span>
    </button>

    <!-- Status chips -->
    <button
      v-for="(status, idx) in statusesOrdered"
      :key="status"
      :ref="(el) => setButtonRef(el, idx + 1)"
      type="button"
      :aria-pressed="selected === status"
      :title="humanReadableParticipationStatus[status]"
      :tabindex="focusedIndex === idx + 1 ? 0 : -1"
      :class="[
        'inline-flex items-center gap-3 px-4 py-1 rounded-full text-sm transition-colors duration-150 ease-out cursor-pointer select-none transform-gpu',
        chipClass(status),
        selected === status ? 'font-semibold shadow' : 'font-medium',
        // selected gets a persistent ring; otherwise show a visible focus ring for keyboard users
        selected === status
          ? ['ring-2', 'ring-offset-1', participationStatusColor[status].ring]
          : [
              'focus-visible:outline-none',
              'focus-visible:scale-105',
              'focus-visible:ring-2',
              'focus-visible:ring-offset-2',
              participationStatusColor[status].ring,
            ],
      ]"
      @click="setSelected(status)"
      @focus="focusedIndex = idx + 1"
      @keydown="onButtonKeydown"
    >
      <!-- show an icon only when this status is selected to avoid extra left space -->
      <Check
        v-if="selected === status"
        :class="[
          'w-4 h-4 stroke-current',
          status === 'GIVEN_UP' ? 'text-slate-900' : 'text-white',
        ]"
        aria-hidden="true"
      />
      <span class="whitespace-nowrap">{{
        humanReadableParticipationStatus[status]
      }}</span>
    </button>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, nextTick, type ComponentPublicInstance } from "vue";
import { Check } from "lucide-vue-next";
import type { ParticipationStatus } from "@/dto";
import {
  humanReadableParticipationStatus,
  participationStatusColor,
} from "@/dto";

const props = defineProps<{
  selected?: ParticipationStatus | null;
}>();

const emit = defineEmits<{
  (e: "update:selected", value: ParticipationStatus | null): void;
}>();

const statusesOrdered: ParticipationStatus[] = [
  "ANNOUNCED",
  "ACCEPTED",
  "CONTACTED",
  "GIVEN_UP",
  "IN_CONVERSATIONS",
  "ON_HOLD",
  "REJECTED",
  "SELECTED",
  "SUGGESTED",
];

const selected = computed<ParticipationStatus | null>({
  get: () => props.selected ?? null,
  set: (val) => emit("update:selected", val),
});

const chipClass = (status: ParticipationStatus) => {
  const color = participationStatusColor[status];
  return `${color.background} border border-transparent`;
};

function setSelected(val: ParticipationStatus | null) {
  selected.value = val;
}

// Keyboard navigation support
const focusedIndex = ref(0);
const chipButtons = ref<(HTMLElement | undefined)[]>([]);
const toolbar = ref<HTMLElement | null>(null);

function focusButton(idx: number) {
  nextTick(() => {
    const buttons = chipButtons.value || [];
    const button = buttons[idx];
    if (button) {
      focusedIndex.value = idx;
      button.focus();
    }
  });
}

function handleNavigationKeydown(e: KeyboardEvent) {
  const key = e.key;
  if (
    key === "ArrowRight" ||
    key === "ArrowDown" ||
    key === "Right" ||
    key === "Down" ||
    key === "39"
  ) {
    e.preventDefault();
    focusedIndex.value =
      (focusedIndex.value + 1) % (statusesOrdered.length + 1);
    focusButton(focusedIndex.value);
    return true;
  } else if (
    key === "ArrowLeft" ||
    key === "ArrowUp" ||
    key === "Left" ||
    key === "Up" ||
    key === "37"
  ) {
    e.preventDefault();
    focusedIndex.value =
      (focusedIndex.value - 1 + statusesOrdered.length + 1) %
      (statusesOrdered.length + 1);
    focusButton(focusedIndex.value);
    return true;
  }
  return false;
}

function onToolbarKeydown(e: KeyboardEvent) {
  if (e.target && (e.target as HTMLElement).tagName === "BUTTON") return;
  handleNavigationKeydown(e);
}

function onButtonKeydown(e: KeyboardEvent) {
  handleNavigationKeydown(e);
}

function setButtonRef(
  el: Element | ComponentPublicInstance | null,
  idx: number,
) {
  if (!chipButtons.value) chipButtons.value = [];
  if (el) {
    chipButtons.value[idx] = (el as HTMLElement) ?? undefined;
  } else {
    chipButtons.value[idx] = undefined;
  }
}
</script>
