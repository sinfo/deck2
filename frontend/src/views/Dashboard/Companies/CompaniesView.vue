<template>
  <MembersCompanies
    :companies="companiesList?.data || []"
    :companiesLoading="isCompaniesLoading"
    :members="membersList?.data || []"
    :eventId="eventStore.selectedEvent?.id || 0"
  />
</template>

<script setup lang="ts">
import { useQuery } from "@pinia/colada";
import { getAllCompanies } from "@/api/companies";
import { computed } from "vue";
import type { AllCompaniesFilter } from "@/dto/companies";
import { useEventStore } from "@/stores/event";
import { getAllMembers } from "@/api/members";
import type { AllMembersFilter } from "@/dto/members";
import MembersCompanies from "@/components/companies/MembersCompanies.vue";

const eventStore = useEventStore();
const companiesFilters = computed<AllCompaniesFilter>(() => ({
  event: eventStore.selectedEvent?.id,
}));

const { data: companiesList, isLoading: isCompaniesLoading } = useQuery({
  key: () => ["companies", JSON.stringify(companiesFilters.value)],
  query: () => getAllCompanies(companiesFilters.value),
});

const membersFilters = computed<AllMembersFilter>(() => ({
  event: eventStore.selectedEvent?.id,
}));

const { data: membersList } = useQuery({
  key: () => ["members", JSON.stringify(membersFilters.value)],
  query: () => getAllMembers(membersFilters.value),
});
</script>
