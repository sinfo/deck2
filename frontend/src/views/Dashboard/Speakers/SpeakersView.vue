<template>
  <MembersSpeakers
    :speakers="speakersList?.data || []"
    :speakers-loading="isSpeakersLoading"
    :members="membersList?.data || []"
    :event-id="eventStore.selectedEvent?.id || 0"
    :coordination-teams="coordinationTeamsList?.data || []"
  />
</template>

<script setup lang="ts">
import { useQuery } from "@pinia/colada";
import { computed } from "vue";
import { useEventStore } from "@/stores/event";
import { getAllMembers } from "@/api/members";
import type { AllMembersFilter } from "@/dto/members";
import MembersSpeakers from "@/components/speakers/MembersSpeakers.vue";
import type { AllSpeakersFilter } from "@/dto/speakers";
import { getAllSpeakers } from "@/api/speakers";
import { getAllCoordinationTeams } from "@/api/coordinationTeams";

const eventStore = useEventStore();
const speakersFilters = computed<AllSpeakersFilter>(() => ({
  event: eventStore.selectedEvent?.id,
}));

const { data: speakersList, isLoading: isSpeakersLoading } = useQuery({
  key: () => ["speakers", JSON.stringify(speakersFilters.value)],
  query: () => getAllSpeakers(speakersFilters.value),
});

const membersFilters = computed<AllMembersFilter>(() => ({
  event: eventStore.selectedEvent?.id,
}));

const { data: membersList } = useQuery({
  key: () => ["members", JSON.stringify(membersFilters.value)],
  query: () => getAllMembers(membersFilters.value),
});

const { data: coordinationTeamsList } = useQuery({
  key: ["coordinationTeams"],
  query: () => getAllCoordinationTeams(),
});
</script>
