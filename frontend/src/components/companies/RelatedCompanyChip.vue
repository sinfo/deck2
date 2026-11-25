<template>
  <RouterLink
    :to="{ name: 'company', params: { companyId: company.company } }"
    :title="title"
    class="inline-flex max-w-full items-center gap-1.5 rounded-full border bg-background py-0.5 pl-0.5 pr-2.5 text-sm text-foreground hover:bg-accent transition-colors"
  >
    <Image
      :src="company.img"
      :alt="`${company.name} logo`"
      class="h-5 w-5 flex-shrink-0 rounded-full object-contain bg-white"
    />
    <span class="truncate font-medium">{{ company.name }}</span>
  </RouterLink>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { RouterLink } from "vue-router";
import type { RelatedCompany } from "@/dto/companies";
import { formatMonthYear } from "@/lib/utils";
import Image from "../Image.vue";

const props = defineProps<{
  company: RelatedCompany;
}>();

const title = computed(() =>
  props.company.since
    ? `${props.company.name} · since ${formatMonthYear(props.company.since)}`
    : props.company.name,
);
</script>
