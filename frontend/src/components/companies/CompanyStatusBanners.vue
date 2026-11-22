<template>
  <div v-if="company.closure" class="space-y-3">
    <!-- Bankrupt / banned -->
    <div
      v-if="company.closure"
      role="alert"
      class="rounded-xl border border-dashed text-foreground"
      :class="
        isBankrupt
          ? 'border-amber-500/40 bg-amber-500/10'
          : 'border-foreground/30 bg-muted/40'
      "
    >
      <div
        class="flex items-start gap-3 px-4"
        :class="isBankrupt ? 'py-4' : 'py-3'"
      >
        <component
          :is="closureIcon"
          class="shrink-0"
          :class="
            isBankrupt
              ? 'mt-0.5 h-5 w-5 text-amber-700 dark:text-amber-400'
              : 'h-4 w-4 text-muted-foreground'
          "
        />
        <div class="min-w-0 space-y-1">
          <p
            class="font-semibold uppercase tracking-wide"
            :class="isBankrupt ? 'text-base' : 'text-sm'"
          >
            {{ companyClosureLabels[company.closure.type] }}
          </p>
          <p
            class="text-muted-foreground leading-snug"
            :class="isBankrupt ? 'text-sm' : 'text-xs'"
          >
            {{ closureDescription }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { BanIcon, TriangleAlertIcon } from "lucide-vue-next";
import { companyClosureLabels, type Company } from "@/dto/companies";
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
    return date
      ? `This company has been banned since ${date}.`
      : "This company is banned.";
  }

  const bankruptcy = date
    ? `This company went bankrupt in ${date}`
    : "This company went bankrupt";

  return `${bankruptcy} and is no longer operating. This page is preserved as a historical record and should only be updated when necessary.`;
});
</script>
