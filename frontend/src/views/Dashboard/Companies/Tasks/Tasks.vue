<template>
  <Tasks
    entity-type="company"
    :entity-id="companyWithParticipation.id"
    :participation="currentParticipation"
    :billing-info="companyWithParticipation.billingInfo"
  />
</template>

<script setup lang="ts">
import { computed } from "vue";
import type { CompanyWithParticipation } from "@/dto/companies";
import Tasks from "@/components/tasks/Tasks.vue";

interface Props {
  companyWithParticipation: CompanyWithParticipation;
}

const props = defineProps<Props>();

const currentParticipation = computed(
  () => props.companyWithParticipation?.participation,
);
</script>
