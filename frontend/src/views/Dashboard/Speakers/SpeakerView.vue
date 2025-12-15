<template>
  <div v-if="speakerWithParticipation" class="flex flex-col lg:flex-row gap-6">
    <!-- Speaker information section -->
    <div class="space-y-6 w-full lg:w-96 lg:flex-shrink-0">
      <!-- Speaker Card -->
      <SpeakerCard
        :speaker="speakerWithParticipation"
        @updated="handleSpeakerUpdated"
      />

      <DirectEmailDialogTrigger
        v-if="speakerWithParticipation"
        :entity="speakerWithParticipation"
        entity-type="speaker"
        button-class="w-full"
      />

      <!-- Speaker Contact -->
      <ContactCard
        v-if="speakerWithParticipation.contactObject"
        :contact="speakerWithParticipation.contactObject"
        :contact-name="speakerWithParticipation.name"
        can-edit
        @updated="handleContactUpdated"
      />
    </div>

    <!-- Communications section -->
    <div class="flex-1 min-w-0">
      <ParticipationsCard
        v-if="speakerWithParticipation?.participations"
        :participations="speakerWithParticipation.participations"
        :entity-id="speakerId as string"
        entity-type="speaker"
        class="mb-5"
      />

      <SpeakerCommunications :speaker="speakerWithParticipation" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { getSpeakerById } from "@/api/speakers";
import SpeakerCard from "@/components/cards/SpeakerCard.vue";
import ContactCard from "@/components/ContactCard.vue";
import ParticipationsCard from "@/components/ParticipationsCard.vue";
import DirectEmailDialogTrigger from "@/components/DirectEmailDialogTrigger.vue";
import type {
  SpeakerWithContactObject,
  SpeakerWithParticipation,
} from "@/dto/speakers";
import { withCurrentParticipation } from "@/lib/utils";
import { useEventStore } from "@/stores/event";

import { useQuery, useQueryCache } from "@pinia/colada";
import { computed } from "vue";
import { useRoute } from "vue-router";
import SpeakerCommunications from "@/components/speakers/SpeakerCommunications.vue";

const route = useRoute();
const queryCache = useQueryCache();

const speakerId = route.params.speakerId;
const { data: speaker } = useQuery({
  key: () => ["speaker", speakerId],
  query: () => getSpeakerById(speakerId as string),
});

const handleSpeakerUpdated = () => {
  // Invalidate the speaker query to refresh the data
  queryCache.invalidateQueries({ key: ["speaker", speakerId] });
};

const eventStore = useEventStore();
const speakerWithParticipation = computed(() => {
  if (!speaker.value?.data || !eventStore.selectedEvent) return null;

  return withCurrentParticipation(
    speaker.value.data,
    eventStore.selectedEvent,
  ) as SpeakerWithParticipation & SpeakerWithContactObject;
});

const handleContactUpdated = () => {
  // Invalidate the representatives query to refresh the data
  queryCache.invalidateQueries({
    key: ["speaker", speakerId],
  });
};
</script>
