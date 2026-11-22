<template>
  <div v-if="company.closure || terminalRelationships.length" class="space-y-3">
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

    <!-- Merged into / now known as another company -->
    <div
      v-for="rel in terminalRelationships"
      :key="`${rel.type}-${rel.company}`"
      role="status"
      class="rounded-xl border border-dashed border-foreground/30 bg-muted/40 text-foreground"
    >
      <div class="flex items-center gap-3 px-4 py-3">
        <component
          :is="rel.type === 'MERGED_INTO' ? GitMergeIcon : RefreshCwIcon"
          class="h-4 w-4 shrink-0 text-muted-foreground"
        />
        <div class="min-w-0 flex flex-wrap items-center gap-x-2 gap-y-1">
          <p class="text-sm font-semibold uppercase tracking-wide">
            {{ companyRelationshipLabels[rel.type] }}
          </p>
          <RelatedCompanyChip :company="rel" />
          <span v-if="rel.since" class="text-xs text-muted-foreground">
            since {{ formatMonthYear(rel.since) }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import {
  BanIcon,
  GitMergeIcon,
  RefreshCwIcon,
  TriangleAlertIcon,
} from "lucide-vue-next";
import {
  companyClosureLabels,
  companyRelationshipLabels,
  type Company,
} from "@/dto/companies";
import { useCompanyRelationshipsQuery } from "@/mutations/companies";
import { formatMonthYear } from "@/lib/utils";
import RelatedCompanyChip from "./RelatedCompanyChip.vue";

const props = defineProps<{
  company: Company;
}>();

const { data: relationships } = useCompanyRelationshipsQuery(
  () => props.company.id,
);

// Relationships meaning the company no longer exists on its own.
const terminalRelationships = computed(() =>
  (relationships.value ?? []).filter(
    (rel) => rel.type === "MERGED_INTO" || rel.type === "REBRANDED_TO",
  ),
);

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
