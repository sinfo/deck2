<template>
  <div
    v-if="relationships?.length"
    class="flex items-center gap-2 text-muted-foreground"
  >
    <div class="h-[1.5px] min-w-3 flex-1 bg-border"></div>
    <Badge
      variant="outline"
      class="max-w-[85%] flex-col items-start gap-1 px-2.5 py-1 text-xs font-normal whitespace-normal"
    >
      <span
        v-for="relationship in relationships"
        :key="`${relationship.type}-${relationship.company}`"
        class="flex min-w-0 flex-wrap items-center gap-x-1.5 gap-y-0.5"
      >
        <Image
          :src="relationship.img"
          :alt="`${relationship.name} logo`"
          class="h-4 w-4 shrink-0 rounded-[2px] bg-white object-contain"
        />
        <span class="wrap-anywhere">
          {{ companyRelationshipLabels[relationship.type] }}
          {{ relationship.name }}
        </span>
        <span v-if="relationship.since" class="text-muted-foreground">
          · {{ formatLandmarkDate(relationship.since) }}
        </span>
      </span>
    </Badge>
    <div class="h-[1.5px] min-w-3 flex-1 bg-border"></div>
  </div>
</template>

<script setup lang="ts">
import {
  companyRelationshipLabels,
  type RelatedCompany,
} from "@/dto/companies";
import { Badge } from "@/components/ui/badge";
import Image from "../Image.vue";

defineProps<{
  relationships?: RelatedCompany[];
}>();

const formatLandmarkDate = (date: string) =>
  new Date(date).toLocaleDateString(undefined, {
    day: "numeric",
    month: "short",
    year: "numeric",
    timeZone: "UTC",
  });
</script>
