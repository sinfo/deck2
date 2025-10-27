<template>
  <Communications
    :entity="company"
    entity-type="company"
    description="Communication history with company representatives"
    :participations="company.participations"
    can-send-messages
    :templates="templates"
    :fetch-communications="getCompanyCommunications"
    :post-thread-mutation="postThreadMutation"
  />
</template>

<script setup lang="ts">
import { getCompanyCommunications } from "@/api/companies";
import type { CompanyWithParticipation } from "@/dto/companies";
import { useEventStore } from "@/stores/event";
import { usePostCompanyThreadMutation } from "@/mutations/companies";
import Communications from "../Communications.vue";
import { companyTemplates, createEmailVariable } from "@/lib/templates";
import { computed } from "vue";

const props = defineProps<{
  company: CompanyWithParticipation;
}>();

const eventStore = useEventStore();

// Setup mutation for posting threads
const postThreadMutation = usePostCompanyThreadMutation();
postThreadMutation.companyId.value = props.company.id;

const templates = computed(() =>
  companyTemplates.map((it) => ({
    template: it,
    variables: createCompanyTemplateVariables(it),
  })),
);

const createCompanyTemplateVariables = () => {
  const endDate = new Date(eventStore.selectedEvent?.end || 0);

  return [
    createEmailVariable.company(props.company),
    createEmailVariable.edition(eventStore.selectedEvent?.id || 0),
    createEmailVariable.editionOrdinal(eventStore.selectedEvent?.id || 0),
    createEmailVariable.eventStartDay(
      new Date(eventStore.selectedEvent?.begin || 0),
    ),
    createEmailVariable.eventEndDay(endDate),
    createEmailVariable.eventEndMonth(endDate),
    createEmailVariable.eventEndYear(endDate),
  ];
};
</script>
