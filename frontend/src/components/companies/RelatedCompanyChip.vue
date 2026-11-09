<template>
  <RouterLink
    :to="{ name: 'company', params: { companyId: company.company } }"
    :title="title"
    :class="[
      'inline-flex max-w-full items-center rounded-full border bg-background text-foreground hover:bg-accent transition-colors',
      size === 'lg'
        ? 'gap-2 py-1 pl-1 pr-4 text-base shadow-sm'
        : 'gap-1.5 py-0.5 pl-0.5 pr-2.5 text-sm',
    ]"
  >
    <Image
      :src="company.img"
      :alt="`${company.name} logo`"
      :class="[
        'flex-shrink-0 rounded-full object-contain bg-white',
        size === 'lg' ? 'h-8 w-8' : 'h-5 w-5',
      ]"
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

const props = withDefaults(
  defineProps<{
    company: RelatedCompany;
    size?: "sm" | "lg";
  }>(),
  { size: "sm" },
);

const title = computed(() =>
  props.company.since
    ? `${props.company.name} · since ${formatMonthYear(props.company.since)}`
    : props.company.name,
);
</script>
