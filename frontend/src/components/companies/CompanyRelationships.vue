<template>
  <div v-if="groups.length" class="space-y-2">
    <div
      v-for="group in groups"
      :key="group.type"
      class="flex flex-wrap items-center gap-x-2 gap-y-1 text-sm"
    >
      <span class="text-muted-foreground">
        {{ companyRelationshipLabels[group.type] }}:
      </span>
      <RelatedCompanyChip
        v-for="rel in group.items"
        :key="rel.company"
        :company="rel"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import {
  companyRelationshipLabels,
  type CompanyRelationshipType,
} from "@/dto/companies";
import { useCompanyRelationshipsQuery } from "@/mutations/companies";
import RelatedCompanyChip from "./RelatedCompanyChip.vue";

const props = defineProps<{
  companyId: string;
}>();

const { data: relationships } = useCompanyRelationshipsQuery(
  () => props.companyId,
);

// MERGED_INTO and REBRANDED_TO are shown above the card (see CompanyStatusBanners).
const typeOrder: CompanyRelationshipType[] = [
  "SUBSIDIARY_OF",
  "REBRANDED_FROM",
  "PARENT_OF",
  "ABSORBED",
];

const groups = computed(() =>
  typeOrder
    .map((type) => ({
      type,
      items: (relationships.value ?? []).filter((rel) => rel.type === type),
    }))
    .filter((group) => group.items.length > 0),
);
</script>
