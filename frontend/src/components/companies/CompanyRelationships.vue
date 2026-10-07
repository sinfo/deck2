<template>
  <div v-if="groups.length" class="space-y-2">
    <div
      v-for="group in groups"
      :key="group.type"
      :class="[
        'flex flex-wrap items-center gap-x-2 gap-y-1 text-sm',
        isTerminal(group.type) &&
          'rounded-md border border-amber-300 bg-amber-50 px-2 py-1.5 dark:border-amber-700 dark:bg-amber-950/40',
      ]"
    >
      <span class="text-muted-foreground">
        {{ companyRelationshipLabels[group.type] }}:
      </span>
      <RouterLink
        v-for="rel in group.items"
        :key="rel.company"
        :to="{ name: 'company', params: { companyId: rel.company } }"
        :title="relationshipTitle(rel)"
        class="inline-flex max-w-full items-center gap-1.5 rounded-full border bg-background py-0.5 pl-0.5 pr-2.5 hover:bg-accent transition-colors"
      >
        <Image
          :src="rel.img"
          :alt="`${rel.name} logo`"
          class="h-5 w-5 flex-shrink-0 rounded-full object-contain bg-white"
        />
        <span class="truncate font-medium">{{ rel.name }}</span>
      </RouterLink>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { RouterLink } from "vue-router";
import {
  companyRelationshipLabels,
  type CompanyRelationshipType,
  type RelatedCompany,
} from "@/dto/companies";
import { useCompanyRelationshipsQuery } from "@/mutations/companies";
import Image from "../Image.vue";

const props = defineProps<{
  companyId: string;
}>();

const { data: relationships } = useCompanyRelationshipsQuery(
  () => props.companyId,
);

// Relationships that mean the company no longer exists on its own come first.
const typeOrder: CompanyRelationshipType[] = [
  "MERGED_INTO",
  "REBRANDED_TO",
  "SUBSIDIARY_OF",
  "REBRANDED_FROM",
  "PARENT_OF",
  "ABSORBED",
];

const isTerminal = (type: CompanyRelationshipType) =>
  type === "MERGED_INTO" || type === "REBRANDED_TO";

const groups = computed(() =>
  typeOrder
    .map((type) => ({
      type,
      items: (relationships.value ?? []).filter((rel) => rel.type === type),
    }))
    .filter((group) => group.items.length > 0),
);

const relationshipTitle = (rel: RelatedCompany) => {
  const parts = [rel.name];
  if (rel.since) {
    parts.push(
      `since ${new Date(rel.since).toLocaleDateString(undefined, { year: "numeric", month: "short" })}`,
    );
  }
  if (rel.notes) parts.push(rel.notes);
  return parts.join(" · ");
};
</script>
