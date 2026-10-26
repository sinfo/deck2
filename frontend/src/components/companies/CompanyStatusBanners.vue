<template>
  <div v-if="company.closure || terminalRelationships.length" class="space-y-3">
    <!-- Bankrupt / banned -->
    <div
      v-if="company.closure"
      role="alert"
      class="relative overflow-hidden rounded-xl bg-neutral-800 text-neutral-50 shadow-lg ring-1 ring-red-400/50"
    >
      <div class="absolute inset-y-0 left-0 w-1.5 bg-red-400/80" />
      <div class="flex min-h-28 items-center gap-5 py-7 pl-7 pr-6">
        <div
          class="flex h-14 w-14 flex-shrink-0 items-center justify-center rounded-full bg-red-400/20 text-red-300"
        >
          <component :is="closureIcon" class="h-7 w-7" />
        </div>
        <div class="min-w-0 space-y-1">
          <p class="text-xl font-extrabold uppercase tracking-wider">
            {{ companyClosureLabels[company.closure.type] }}
          </p>
          <p class="text-sm text-neutral-300">
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
      class="relative overflow-hidden rounded-xl bg-amber-50 text-amber-950 shadow-md ring-1 ring-amber-300 dark:bg-amber-950/40 dark:text-amber-100 dark:ring-amber-700"
    >
      <div class="absolute inset-y-0 left-0 w-1.5 bg-amber-400" />
      <div class="flex min-h-28 items-center gap-5 py-6 pl-7 pr-6">
        <div
          class="flex h-14 w-14 flex-shrink-0 items-center justify-center rounded-full bg-amber-200/70 text-amber-700 dark:bg-amber-800/50 dark:text-amber-200"
        >
          <component
            :is="rel.type === 'MERGED_INTO' ? GitMergeIcon : RefreshCwIcon"
            class="h-7 w-7"
          />
        </div>
        <div class="min-w-0 space-y-2">
          <p
            class="text-xs font-bold uppercase tracking-wider text-amber-800 dark:text-amber-300"
          >
            {{ companyRelationshipLabels[rel.type] }}
          </p>
          <div class="flex flex-wrap items-center gap-x-3 gap-y-1">
            <RelatedCompanyChip :company="rel" size="lg" />
            <span
              v-if="rel.since"
              class="text-sm text-amber-800 dark:text-amber-300"
            >
              since {{ formatMonthYear(rel.since) }}
            </span>
          </div>
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
  TrendingDownIcon,
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

const closureIcon = computed(() =>
  props.company.closure?.type === "BANNED" ? BanIcon : TrendingDownIcon,
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

  return date
    ? `This company went bankrupt in ${date} and is no longer operating.`
    : "This company went bankrupt and is no longer operating.";
});
</script>
