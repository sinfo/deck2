<template>
  <div v-if="company.closure" class="space-y-3">
    <div
      role="alert"
      class="rounded-xl border border-dashed text-foreground"
      :class="
        isBankrupt
          ? 'border-amber-500/40 bg-amber-500/10'
          : 'border-red-500/40 bg-red-500/10'
      "
    >
      <div class="flex items-center gap-3 px-4 py-4">
        <component
          :is="closureIcon"
          class="shrink-0"
          :class="
            isBankrupt
              ? 'h-6 w-6 text-amber-700 dark:text-amber-400'
              : 'h-6 w-6 text-red-700 dark:text-red-400'
          "
        />
        <p class="min-w-0 text-base font-normal leading-relaxed text-muted-foreground">
          {{ closureDescription }}
        </p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { BanIcon, TriangleAlertIcon } from "lucide-vue-next";
import type { Company } from "@/dto/companies";
import { formatMonthYear } from "@/lib/utils";

const props = defineProps<{
  company: Company;
}>();

const isBankrupt = computed(() => props.company.closure?.type === "BANKRUPT");

const closureIcon = computed(() =>
  props.company.closure?.type === "BANNED" ? BanIcon : TriangleAlertIcon,
);

const closureDescription = computed(() => {
  const closure = props.company.closure;
  if (!closure) return "";

  const date = closure.since ? formatMonthYear(closure.since) : null;

  if (closure.type === "BANNED") {
    const ban = date
      ? `This company has been banned since ${date}.`
      : "This company is banned.";
    return `${ban} This page is retained for historical reference and should only be updated when necessary.
    Please contact coordination if you need any further information.`;
  }

  const bankruptcy = date
    ? `This company went bankrupt in ${date}`
    : "This company went bankrupt";

  return `${bankruptcy} and is no longer operating. This page is preserved as a historical record and should only be updated when necessary.`;
});
</script>
