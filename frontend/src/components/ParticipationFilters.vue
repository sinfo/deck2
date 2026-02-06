<template>
  <div
    class="flex flex-wrap gap-2 my-4 items-center"
    role="group"
    aria-label="Filter by participation status"
  >
    <!-- Package filter (only shown when packages are provided) -->
    <template v-if="packages && packages.length > 0">
      <Select v-model="selectedPackageModel">
        <SelectTrigger
          class="h-8 w-auto min-w-[140px] rounded-full text-sm font-medium"
        >
          <Package class="size-3.5" aria-hidden="true" />
          <SelectValue placeholder="All Packages" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem :value="ALL_PACKAGES_VALUE"> All Packages </SelectItem>
          <SelectItem v-for="pkg in packages" :key="pkg.id" :value="pkg.id">
            {{ pkg.name }}
          </SelectItem>
        </SelectContent>
      </Select>
    </template>

    <!-- All chip -->
    <button
      type="button"
      :aria-pressed="selected === null"
      aria-label="Show all participations"
      :class="[
        'inline-flex items-center h-8 px-3.5 rounded-full transition-all duration-150 cursor-pointer',
        selected === null
          ? 'bg-slate-900 text-white shadow-sm hover:bg-slate-800'
          : 'bg-slate-100 text-slate-600 hover:bg-slate-200',
      ]"
      @click="setSelected(null)"
    >
      <Check
        v-if="selected === null"
        class="size-3.5 mr-1"
        aria-hidden="true"
      />
      <span class="text-sm font-medium">All</span>
    </button>

    <Separator orientation="vertical" class="h-8 mx-1" />

    <!-- Status chips -->
    <button
      v-for="status in statusesOrdered"
      :key="status"
      type="button"
      :aria-pressed="selected === status"
      :aria-label="humanReadableParticipationStatus[status]"
      :class="[
        'inline-flex items-center h-8 px-3.5 rounded-full transition-all duration-150 cursor-pointer',
        selected === status
          ? [
              statusStyles[status].selectedBg,
              statusStyles[status].selectedText,
              statusStyles[status].selectedHoverBg,
              'shadow-sm',
            ]
          : [
              statusStyles[status].defaultBg,
              statusStyles[status].defaultText,
              statusStyles[status].defaultHoverBg,
            ],
      ]"
      @click="setSelected(status)"
    >
      <Check
        v-if="selected === status"
        class="size-3.5 mr-1"
        aria-hidden="true"
      />
      <span class="text-sm font-medium whitespace-nowrap">
        {{ humanReadableParticipationStatus[status] }}
      </span>
    </button>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { Check, Package } from "lucide-vue-next";
import { Separator } from "@/components/ui/separator";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import type { ParticipationStatus, ObjectID } from "@/dto";
import { humanReadableParticipationStatus } from "@/dto";
import type { Package as PackageType } from "@/dto/packages";

// Special value to represent "All Packages" since Select doesn't handle null well
const ALL_PACKAGES_VALUE = "__all__";

const props = defineProps<{
  selected?: ParticipationStatus | null;
  packages?: PackageType[];
  selectedPackage?: ObjectID | null;
}>();

const emit = defineEmits<{
  (e: "update:selected", value: ParticipationStatus | null): void;
  (e: "update:selectedPackage", value: ObjectID | null): void;
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

// Status-specific styling with solid colors
const statusStyles: Record<
  ParticipationStatus,
  {
    selectedBg: string;
    selectedText: string;
    selectedHoverBg: string;
    defaultBg: string;
    defaultText: string;
    defaultHoverBg: string;
  }
> = {
  SUGGESTED: {
    selectedBg: "bg-amber-400",
    selectedText: "text-amber-950",
    selectedHoverBg: "hover:bg-amber-500",
    defaultBg: "bg-amber-100",
    defaultText: "text-amber-800",
    defaultHoverBg: "hover:bg-amber-200",
  },
  SELECTED: {
    selectedBg: "bg-violet-500",
    selectedText: "text-white",
    selectedHoverBg: "hover:bg-violet-600",
    defaultBg: "bg-violet-100",
    defaultText: "text-violet-800",
    defaultHoverBg: "hover:bg-violet-200",
  },
  ON_HOLD: {
    selectedBg: "bg-zinc-500",
    selectedText: "text-white",
    selectedHoverBg: "hover:bg-zinc-600",
    defaultBg: "bg-zinc-200",
    defaultText: "text-zinc-700",
    defaultHoverBg: "hover:bg-zinc-300",
  },
  CONTACTED: {
    selectedBg: "bg-orange-400",
    selectedText: "text-orange-950",
    selectedHoverBg: "hover:bg-orange-500",
    defaultBg: "bg-orange-100",
    defaultText: "text-orange-800",
    defaultHoverBg: "hover:bg-orange-200",
  },
  IN_CONVERSATIONS: {
    selectedBg: "bg-sky-500",
    selectedText: "text-white",
    selectedHoverBg: "hover:bg-sky-600",
    defaultBg: "bg-sky-100",
    defaultText: "text-sky-800",
    defaultHoverBg: "hover:bg-sky-200",
  },
  ACCEPTED: {
    selectedBg: "bg-lime-500",
    selectedText: "text-lime-950",
    selectedHoverBg: "hover:bg-lime-600",
    defaultBg: "bg-lime-100",
    defaultText: "text-lime-800",
    defaultHoverBg: "hover:bg-lime-200",
  },
  REJECTED: {
    selectedBg: "bg-red-500",
    selectedText: "text-white",
    selectedHoverBg: "hover:bg-red-600",
    defaultBg: "bg-red-100",
    defaultText: "text-red-800",
    defaultHoverBg: "hover:bg-red-200",
  },
  GIVEN_UP: {
    selectedBg: "bg-slate-400",
    selectedText: "text-slate-950",
    selectedHoverBg: "hover:bg-slate-500",
    defaultBg: "bg-slate-200",
    defaultText: "text-slate-700",
    defaultHoverBg: "hover:bg-slate-300",
  },
  ANNOUNCED: {
    selectedBg: "bg-green-600",
    selectedText: "text-white",
    selectedHoverBg: "hover:bg-green-700",
    defaultBg: "bg-green-100",
    defaultText: "text-green-800",
    defaultHoverBg: "hover:bg-green-200",
  },
};

const selected = computed<ParticipationStatus | null>({
  get: () => props.selected ?? null,
  set: (val) => emit("update:selected", val),
});

const selectedPackageModel = computed<string>({
  get: () => props.selectedPackage ?? ALL_PACKAGES_VALUE,
  set: (val) =>
    emit("update:selectedPackage", val === ALL_PACKAGES_VALUE ? null : val),
});

function setSelected(val: ParticipationStatus | null) {
  selected.value = val;
}
</script>
